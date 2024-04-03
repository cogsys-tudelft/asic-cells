def chunk_list(input_list: list, chunk_size: int):
    """Chunk a list into smaller lists of a given size.

    Args:
        input_list (list): Input list
        chunk_size (int): Size of the chunks

    Returns:
        list[list]: List of chunks of size `chunk_size` from `input_list`
    """

    return [input_list[i:i+chunk_size] for i in range(0, len(input_list), chunk_size)]


def to_binary_string(value: int, n_bits: int):
    """Function to convert integer to binary string with certain bit width.

    Args:
        value (int): Value to convert
        n_bits (int): Bit width of the output

    Returns:
        str: Binary string
    """

    assert value >= 0, "Value must be non-negative"
    assert value < 2**n_bits, f"Value exceeds the maximum possible value for the given bit width (max: {2**n_bits-1})"

    return format(value, f"0{n_bits}b")
