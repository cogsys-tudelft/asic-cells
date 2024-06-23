from typing import Union, List, Dict
import random
import warnings

from asic_cells.utils import chunk_list, to_binary_string


def _compute_start_address(config_sizes_and_names: list):
    start_addresses = {}

    last_start = 0

    for name, entry_width in [(entry[1], entry[0]) for entry in config_sizes_and_names]:
        start_addresses[name] = last_start

        number_of_entries = 1

        if type(entry_width) is list:
            if type(entry_width[1]) is list:
                number_of_entries = entry_width[1][0] - entry_width[1][1]
            else:
                number_of_entries = entry_width[1]

        last_start += number_of_entries

    return start_addresses


class SpiMessageCreator:
    def __init__(self, message_bit_width: int, code_bit_width: int, address_bit_width: int, config_sizes_and_names: list, pointer_sizes_and_names: list, memory_sizes_and_names: Dict):
        self.message_bit_width = message_bit_width
        self.code_bit_width = code_bit_width
        self.address_bit_width = address_bit_width
        self.num_transactions_bit_width = message_bit_width - code_bit_width - address_bit_width - 1

        self.config_sizes_and_names = config_sizes_and_names
        self.pointer_sizes_and_names = pointer_sizes_and_names
        self.memory_sizes_and_names = memory_sizes_and_names

        if "config_sizes_and_names" in config_sizes_and_names:
            warnings.warn("You likely forgot select the entry with key 'config_sizes_and_names' after loading the json configuration file into a dictionary")

        if "pointer_sizes_and_names" in pointer_sizes_and_names:
            warnings.warn("You likely forgot to select the entry with key 'pointer_sizes_and_names' after loading the json configuration file into a dictionary")

        self._config_start_addresses = _compute_start_address(self.config_sizes_and_names)
        self._pointer_addresses = dict(map(lambda x: (x[1][1], x[0]), enumerate(self.pointer_sizes_and_names)))

        memory_indices = range(len(self.memory_sizes_and_names))
        max_memory_addresses = map(int, map(lambda x: self.memory_sizes_and_names[x]["num_rows"] * self.memory_sizes_and_names[x]["bit_width"] / self.message_bit_width, self.memory_sizes_and_names))

        self._memory_indices_and_max_addresses = dict(zip(self.memory_sizes_and_names.keys(), zip(memory_indices, max_memory_addresses)))

    def _create_instruction_message(self, read: bool, code: int, start_address: int, num_transactions: int):
        """Create an instruction/header message for the SPI interface.

        Format of the message: read(1)/write(0) | code | start_address | num_transactions

        Args:
            read (bool): Whether the message is a read or write message
            code (int): Code/location of the data to be read/written
            start_address (int): Start address of the data to be read/written
            num_transactions (int): Number of transactions to be read/written

        Returns:
            str: Binary string of the message of length `self.message_bit_width`
        """

        bin_read = to_binary_string(read * 1, 1)
        bin_code = to_binary_string(code, self.code_bit_width)
        bin_start_address = to_binary_string(start_address, self.address_bit_width)
        bin_num_transactions = to_binary_string(num_transactions, self.num_transactions_bit_width)

        return bin_read + bin_code + bin_start_address + bin_num_transactions
    
    def create_config_messages(self, config: Dict[str, Union[int, List[int]]]):
        """Create messages that write to the configuration memory.

        Args:
            config (Dict[str, Union[int, List[int]]]): Dictionary with the configuration values

        Returns:
            List[int]: List of integers representing the binary messages
        """

        messages = []

        for key, value in config.items():
            is_value_list = type(value) is list

            messages.append(self._create_instruction_message(False, 0, self._config_start_addresses[key], len(value) if is_value_list else 1))
            
            if is_value_list:
                config_size = next(entry[0] for entry in self.config_sizes_and_names if entry[1] == key)

                if type(config_size) is int:
                    raise ValueError(f"Cannot store a list-type value in a single-value configuration register")
                
                _, config_size_length = config_size
                
                num_entries = config_size_length if type(config_size_length) is int else config_size_length[0] - config_size_length[1]

                if len(value) <= num_entries:
                    for entry in value:
                        messages.append(self.create_data_message(entry))
                else:
                    raise ValueError(f"Too many entries for {key} (max: {num_entries})")
            else:
                messages.append(self.create_data_message(value))

        return messages
    
    def create_pointer_message(self, key: str):
        """Create a message to read from the pointer memory.

        Args:
            key (str): Pointer name

        Returns:
            str: Binary string of the message of length `self.message_bit_width`
        """

        # TODO: only size 1????//
        return self._create_instruction_message(True, 0, self._pointer_addresses[key], 1)
    
    def create_write_memory_messages(self, key: str, data: list[int], start_address: int = 0):
        code, max_data_length = self._memory_indices_and_max_addresses[key]

        assert start_address >= 0, "Start address must be non-negative"
        assert len(data) > 0, "Data must not be empty"

        # We add plus one to the code as code 0 is the configuration memory
        code += 1

        if len(data) + start_address > max_data_length:
            raise ValueError(f"Too many transactions ({len(data)}) for {key} at start address {start_address} (max: {max_data_length-start_address})")

        messages = []

        for chunk in chunk_list(data, 2**self.num_transactions_bit_width-1):
            messages.append(self._create_instruction_message(False, code, start_address, len(chunk)))

            messages += list(map(self.create_data_message, chunk))

            start_address += len(chunk)
        
        return messages
    
    def create_read_memory_message(self, key: str, start_address: int, num_transactions: int):
        """Create a message to read from a memory.

        Args:
            key (str): Memory name
            start_address (int): Start address of the data to be read
            num_transactions (int): Number of transactions to be read

        Returns:
            str: Binary string of the message of length `self.message_bit_width`
        """

        code, max_data_length = self._memory_indices_and_max_addresses[key]

        assert start_address >= 0, "Start address must be non-negative"
        assert num_transactions > 0, "Number of transactions must be positive"

        # We add plus one to the code as code 0 is the configuration memory
        code += 1

        if start_address + num_transactions > max_data_length:
            raise ValueError(f"Too many transactions for {key} at start address {start_address} (max: {max_data_length-start_address})")

        return self._create_instruction_message(True, code, start_address, num_transactions)
    
    def create_random_data_message(self):
        """Create a randomly-valued data message of length `self.message_bit_width`

        Returns:
            str: Binary string of the message of length `self.message_bit_width`
        """

        data = random.randint(0, 2**self.message_bit_width-1)

        return self.create_data_message(data)

    def create_data_message(self, data: int):
        """Create an SPI data message from some data using the SPI message bit width.

        Args:
            data (int): Data to be converted into an SPI message

        Returns:
            str: Binary string of the message of length `self.message_bit_width`
        """

        return to_binary_string(data, self.message_bit_width)
