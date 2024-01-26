import random

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
from cocotb.binary import BinaryValue

PERIOD = 1

def set_write(dut, address, data, mask):
    dut.CEB.value = 0
    dut.WEB .value= 0
    dut.A.value = address
    dut.D.value = data
    dut.M.value = mask

def set_read(dut, address, mask):
    dut.CEB.value = 0
    dut.WEB.value = 1
    dut.A.value = address
    dut.M.value = mask # With or without mask should not matter


def generate_random_binary_value(num_bits):
    return random.getrandbits(num_bits)


@cocotb.test()
async def check_everything(dut):
    sram_width = int(dut.WIDTH)
    sram_rows = int(dut.NUM_ROWS)
    full_mask = int("1" * sram_width, 2)

    # Setup
    dut.CEB.value = 1 # Disable SRAM
    dut.WEB.value = 1 # Disable writing to SRAM

    cocotb.start_soon(Clock(dut.CLK, PERIOD, units="ns").start())
    await Timer(3*PERIOD, units="ns")

    for read_mask in (0, full_mask, generate_random_binary_value(sram_width)):
        values = []

        for write_mask in (0, full_mask, generate_random_binary_value(sram_width)):
            for address in range(int(dut.NUM_ROWS)+1):
                await RisingEdge(dut.CLK)

                data = BinaryValue(generate_random_binary_value(sram_width), n_bits=sram_width)     

                # Don't write in the last cycle
                if address < sram_rows:
                    set_write(dut, address, data, write_mask)

                await RisingEdge(dut.CLK)

                # Don't issue a read in the last cycle
                if address < sram_rows:
                    set_read(dut, address, read_mask)

                # Can only check the output of the SRAM in the next cycle
                if address > 0:
                    if write_mask == 0:
                        correct_value = values[-1]
                    elif write_mask == full_mask: # If nothing was written
                        correct_value = values[address-1]
                    else: # If only some bits were written
                        correct_value = (values[address-1] & write_mask) | (values[-1] & ~write_mask)

                    assert dut.Q.value == correct_value, f"Expected {correct_value}, got {dut.Q.value} at address {address-1}"

                if write_mask != full_mask:
                    values.append(data)
