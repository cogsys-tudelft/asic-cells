# ASIC cells

**This library has been developed by the [Cognitive Sensor Nodes and Systems lab](https://ei.et.tudelft.nl/Research/theme.php?id=63) at Delft University of Technology.**

This repository contains a set of (System)Verilog modules that can be used in ASIC design. Tests for these modules are also provided and created using [cocotb](https://github.com/cocotb/cocotb).
The modules are divided into the following categories:

## AER (Address Event Representation)

Two modules are present for AER communication: [`high_speed_in_bus`](./src/aer/high_speed_in_bus.v) and [`high_speed_out_bus`](./src/aer/high_speed_out_bus.v). These modules are used to communicate with a chip that uses AER communication. The modules are based on the [AER protocol](https://jamesmccaffrey.wordpress.com/2020/01/03/address-event-representation-for-spiking-neural-networks/) for spiking neural networks.

The in-bus handles the incoming and outgoing request and acknowledge signals, while the out-bus handles the sending of (multiple) output data.

## Clock

The clock directory contains a clock divider ([`clock_divider`](./src/clock/clock_divider.v), number of stages can be specified via a parameter) and a simple OR gate ([`ext_or_int_clock`](./src/clock/ext_or_int_clock.v)) that switches between an external and internal clock to make SDC constraint definitions easier.

## Clock domain crossing (CDC)

Two domain crossing modules are provided: a [`double_flop_synchronizer`](./src/domain_crossing/double_flop_synchronizer.v) and a [`triple_flop_synchronizer`](./src/domain_crossing/triple_flop_synchronizer.v). For the triple flop synchronizer, there is also a variant where the output goes high if the input toggles: [`triple_flop_toggle_synchronizer`](./src/domain_crossing/triple_flop_toggle_synchronizer.v), while also a wide (multi-bit) version of the double flop synchronizer is provided: [`wide_double_flop_synchronizer`](./src/domain_crossing/wide_double_flop_synchronizer.v). All of these modules can be used to cross from a slow clock domain (input data) to a fast clock domain. For more information about clock domain crossing see [here](https://electrobinary.blogspot.com/2020/06/double-flop-synchronizer.html) for information about a double flop synchronizer and [here](https://www.verilogpro.com/clock-domain-crossing-part-1/) for information about clock domain crossing in general.

## SRAM

Two parametrizable SRAM modules are provided: a single port memory with write mask ([`single_port_type_t_sram.sv`](./src/sram/single_port_type_t_sram.sv)) and a dual port memory ([`dual_port_type_t_sram.sv`](./src/sram/dual_port_type_t_sram.sv)) with write mask. Note that the dual port memory supports one read and write in parallel, but not two writes or two reads in parallel.
