from jinja2 import Template

pointer_names = [
    "chameleon_inst.pe_array_control_inst.load_scale_and_bias",
    "chameleon_inst.high_speed_in_bus_inst.request_sync"
]


with open("pointers.v.jinja2") as t:
    template = Template(t.read(),
                        trim_blocks=True, lstrip_blocks=True)

    with open("pointers.v", "w") as r:
        r.write(template.render(pointer_names=pointer_names))
