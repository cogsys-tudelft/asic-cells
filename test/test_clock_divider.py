from pathlib import Path

import pytest

from cocotb_test.simulator import run


@pytest.mark.parametrize("parameters", [{"NUM_STAGES": "1"}, {"NUM_STAGES": "2"}, {"NUM_STAGES": "3"}, {"NUM_STAGES": "7"}])
def test_clock_divider(parameters):
    module_name = "clock_divider"

    file_dir = Path(__file__).resolve().parent
    source_dir = str(file_dir / ".." / "src" / "clock")

    run(
        simulator="verilator",
        verilog_sources=[f"{source_dir}/{module_name}.v"],
        toplevel=module_name,
        module=f"tests.{module_name}_tests",
        parameters=parameters,
        compile_args=[f"+incdir+{source_dir}"],
        extra_args=["--trace", "--coverage"],
    )


if __name__ == "__main__":
    test_clock_divider({"NUM_STAGES": "2"})
