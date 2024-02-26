from typing import List, Tuple, Union

from pathlib import Path

from jinja2 import Template

ConfigurationList = List[Tuple[Union[Union[int, str], Tuple[Union[str, int], Union[int, Tuple[int, int]]]], str, bool]]

TEMPLATE_PATH = Path(__file__).resolve().parent / "config_memory.sv.jinja2"


def generate_config_memory(config_sizes_and_names: ConfigurationList):
    """Generate a configuration memory for use together with the SPI interface.

    Note that every entry in the supplied ConfigurationList should have a bit width that is, at maximum, equal to the MESSAGE_BIT_WIDTH. Otherwise the variable will not be handled correctly in hardware.

    Args:
        config_sizes_and_names (ConfigurationList): A list of tuples containing the name and size of each configuration variable. In human-readable format, the type is: [(bit_width [int/str] | (bit_width [int/str], count [int] | (max_index [int], start_index [int])), name, requires_reset)]
    """

    # Take all bit widths that are not integers
    parameters = [x[0] for x in config_sizes_and_names if type(x[0]) is str] + \
        [x[0][0] for x in config_sizes_and_names if type(x[0]) is list and type(x[0][0]) is str] + \
            [x[0][1] for x in config_sizes_and_names if type(x[0]) is list and type(x[0][1]) is str]

    split_parameters = []

    # Find all '-' and '+' characters in each of the parameters, split these parameters and add them to the list
    for p in parameters:
        p = p.replace(" ", "")

        if "-" in p:
            split_parameters.extend(p.split("-"))
        elif "+" in p:
            split_parameters.extend(p.split("+"))
        else:
            split_parameters.append(p)

    # Remove all duplicates
    parameters = list(set(split_parameters))

    config_address_mapping = []
    config_start_address_mapping = {}

    current_address = 0

    for i, (bit_width, name, _) in enumerate(config_sizes_and_names):
        if type(bit_width) is list:
            end_point = bit_width[1]
            start_point = 0

            if type(bit_width[1]) is list:
                end_point = bit_width[1][0]
                start_point = bit_width[1][1]

            for dimension in range(start_point, end_point):
                config_address_mapping.append((current_address + dimension - start_point, f"{name}[{dimension}]", bit_width[0]))

            config_start_address_mapping[name] = current_address
            current_address += (end_point - start_point)
        else:
            config_address_mapping.append((current_address, name, bit_width))
            config_start_address_mapping[name] = current_address
            current_address += 1

    with open(TEMPLATE_PATH) as t:
        template = Template(t.read(),
                            trim_blocks=True, lstrip_blocks=True)
        
        return template.render(
                parameters=parameters,
                config_address_mapping=config_address_mapping,
                config_sizes_and_names=config_sizes_and_names,
            )


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser()

    parser.add_argument("--path_to_json", help="Path to the JSON file containing the config_sizes_and_names variable", type=str, required=True)
    args = parser.parse_args()
    
    # Get current cwd
    cwd = Path.cwd()

    json_path = cwd / args.path_to_json
    json_file_name, json_dir = json_path.name, json_path.parent

    output_file_name = json_file_name[:-5] + ".sv"

    with open(json_path) as f:
        config_sizes_and_names = json.load(f)["config_sizes_and_names"]

    config_memory_verilog = generate_config_memory(config_sizes_and_names)

    with open(json_dir / output_file_name, "w") as f:
        f.write(config_memory_verilog)
