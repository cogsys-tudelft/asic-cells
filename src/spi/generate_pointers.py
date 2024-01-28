from typing import List, Tuple, Union

from pathlib import Path

from copy import deepcopy

from jinja2 import Template

PointerList = List[Union[Tuple[Union[int, str], str], Tuple[Union[int, str], str, str]]]

TEMPLATE_PATH = Path(__file__).resolve().parent / "pointers.v.jinja2"


def generate_pointers(pointer_sizes_and_names: PointerList):
    """Generate a pointer bridge for use together with the SPI interface.

    Args:
        pointer_sizes_and_names (PointerList): A list of tuples containing the name and size of each pointer variable. In human-readable format, the type is: [(bit_width [int/str], name [str]) | (value [str])]
    """

    # Take all bit_widths that are not integers and start with a letter
    parameters = [x[0] for x in pointer_sizes_and_names if type(x[0]) is not int and x[0][0].isalpha()]

    split_parameters = []

    # Find all '-' and '+' characters in each of the parameters, split these parameters and add them to the list
    for p in parameters:
        if "-" in p:
            split_parameters.extend(p.split("-"))
        elif "+" in p:
            split_parameters.extend(p.split("+"))
        else:
            split_parameters.append(p)

    # Remove all duplicates
    parameters = list(set(split_parameters))

    pointer_sizes_and_names_with_values = deepcopy(pointer_sizes_and_names)

    for i, entry in enumerate(pointer_sizes_and_names_with_values):
        listed = list(entry)

        if len(listed) == 1:
            listed.insert(0, -1)

        pointer_sizes_and_names_with_values[i] = listed

    print(pointer_sizes_and_names_with_values)

    with open(TEMPLATE_PATH) as t:
        template = Template(t.read(),
                            trim_blocks=True, lstrip_blocks=True)

        return template.render(pointer_sizes_and_names=pointer_sizes_and_names_with_values, parameters=parameters)


if __name__ == "__main__": 
    import argparse
    import json

    parser = argparse.ArgumentParser()

    parser.add_argument("--path_to_json", help="Path to the JSON file containing the pointer_sizes_and_names variable", type=str, required=True)
    args = parser.parse_args()
    
    # Get current cwd
    cwd = Path.cwd()

    json_path = cwd / args.path_to_json
    json_file_name, json_dir = json_path.name, json_path.parent

    output_file_name = json_file_name[:-5] + ".sv"

    with open(json_path) as f:
        pointer_sizes_and_names = json.load(f)["pointer_sizes_and_names"]

    pointers_verilog = generate_pointers(pointer_sizes_and_names)

    with open(json_dir / output_file_name, "w") as f:
        f.write(pointers_verilog)
