import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

PERIOD = 1
NUM_CHECKS = 5


@cocotb.test()
async def check_everything(dut):
    stage_count = int(dut.NUM_STAGES)

    # Setup
    dut.rst.value = 1 # Reset clock divider

    # Test posedge reset behavior
    await Timer(0.1*PERIOD, units="ns")
    assert dut.clk_div.value == 0, "Clock divider should be reset to 0 after posedge reset"

    cocotb.start_soon(Clock(dut.clk, PERIOD, units="ns").start())
    await Timer(3*PERIOD, units="ns")

    await RisingEdge(dut.clk)
    dut.rst.value = 0
    assert dut.clk_div.value == 0, "Clock divider should be reset to 0 after reset"

    await RisingEdge(dut.clk)

    half_period_cycles = 2**(stage_count-1)

    for _ in range(NUM_CHECKS):
        for _ in range(half_period_cycles):
            await RisingEdge(dut.clk)
            assert dut.clk_div.value == 1, "Clock divider should be 1 for half period cycles"

        for _ in range(half_period_cycles):
            await RisingEdge(dut.clk)
            assert dut.clk_div.value == 0, "Clock divider should be 0 for half period cycles"

    # Test posedge reset behavior during operation
    dut.rst.value = 1
    await Timer(0.1*PERIOD, units="ns")
    assert dut.clk_div.value == 0, "Clock divider should be reset to 0 after posedge reset"
