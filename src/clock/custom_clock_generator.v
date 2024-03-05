`ifndef __CUSTOM_CLOCK_GENERATOR_V__
`define __CUSTOM_CLOCK_GENERATOR_V__

module custom_clock_generator
    #(parameter integer CYCLE_WIDTH = 16)
    (
        input arst,
        input clk_in,
        input enable,
        input [CYCLE_WIDTH-1:0] cycles,
        output reg clk_out
    );

    custom_clock_with_phase_generator #(
        .CYCLE_WIDTH(CYCLE_WIDTH)
    ) custom_clock_with_phase_generator_inst (
        .arst(arst),
        .clk_in(clk_in),
        .enable(enable),
        .high_phase_cycles(cycles),
        .low_phase_cycles(cycles),
        .clk_out(clk_out)
    );

endmodule

`endif
