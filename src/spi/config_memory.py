from jinja2 import Template

# EVERY ENTRY IN THIS LIST BELOW SHOULD HAVE A BIT_WIDTH OF MAXIMUM THE MESSAGE BIT WIDTH!!!

ConfigurationList = List[Tuple[Union[Union[int, str] , Tuple[Union[str, int], Union[int, Tuple[int, int]]]], str, bool]]

# bit_width [int/str] | (bit_width [int/str], count [int] | (max_index [int], start_index [int])), name, requires_reset
config_sizes_and_names: ConfigurationList = [
    (1, "enable_processing", True),
    ("MODE_BIT_WIDTH", "mode", True),
    (1, "continuous_processing", True),
    (1, "enable_clock_divider", True),
    ("LAYER_WIDTH", "num_conv_layers_minus_one", False),
    ("LAYER_WIDTH", "num_conv_and_linear_layers", False),
    (("KERNEL_WIDTH", 32), "kernel_size_per_layer", False),
    (("BLOCKS_WIDTH", 33), "blocks_per_layer", False),
    (("BLOCKS_KERNEL_WIDTH", 32), "blocks_per_layer_times_kernel_size", False),
    (("CUMSUM_WIDTH", (32, 2)), "blocks_per_layer_times_kernel_size_cumsum", False)
]


# Take all bit_widths that are not integers
parameters = [x[0] for x in config_sizes_and_names if type(x[0]) is not int]
# Remove all entries that still have a tuple 
for i in range(len(parameters)):
    if type(parameters[i]) is tuple:
        parameters[i] = parameters[i][0]
# Remove all duplicates
parameters = list(set(parameters))

config_address_mapping = []
config_start_address_mapping = {}

current_address = 0


for i, (bit_width, name, _) in enumerate(config_sizes_and_names):
    if type(bit_width) is tuple:
        end_point = bit_width[1]
        start_point = 0

        if type(bit_width[1]) is tuple:
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


with open("config_memory.sv.jinja2") as t:
    template = Template(t.read(),
                        trim_blocks=True, lstrip_blocks=True)

    with open("config_memory.sv", "w") as r:
        r.write(
            template.render(
                parameters=parameters,
                config_address_mapping=config_address_mapping,
                config_sizes_and_names=config_sizes_and_names,
            )
        )

print(config_start_address_mapping)
