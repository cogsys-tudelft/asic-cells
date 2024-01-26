from pathlib import Path

import pytest

from cocotb_test.simulator import run


@pytest.mark.parametrize("parameters", [{"WIDTH": "8", "NUM_ROWS": "128"}, {"WIDTH": "3", "NUM_ROWS": "47"}, {"WIDTH": "128", "NUM_ROWS": "256"}])
def test_single_port_tsmc_sram(parameters):
    module_name = "single_port_tsmc_sram"

    file_dir = Path(__file__).resolve().parent
    source_dir = str(file_dir / ".." / "src" / "sram")

    run(
        simulator="verilator",
        verilog_sources=[f"{source_dir}/{module_name}.sv"],
        toplevel=module_name,
        module=f"tests.{module_name}_tests",
        parameters=parameters,
        compile_args=[f"+incdir+{source_dir}"], #  '--x-assign unique', '--x-initial unique'
        extra_args=["--trace", "--coverage"], # Store a VCD file in the sim_build directory
    )


if __name__ == "__main__":
    test_single_port_tsmc_sram({"WIDTH": "8", "NUM_ROWS": "128"})
