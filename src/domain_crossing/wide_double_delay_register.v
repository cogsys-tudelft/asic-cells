`ifndef __WIDE_DOUBLE_DELAY_REGISTER_V__
`define __WIDE_DOUBLE_DELAY_REGISTER_V__

`include "double_delay_register.v"

module wide_double_delay_register #(
    parameter integer WIDTH = 8
) (
    input clk,
    input rst,

    input  [WIDTH-1:0] in,
    output [WIDTH-1:0] in_delayed
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_wide_double_delay_register
            double_delay_register double_delay_register_inst (
                .clk(clk),
                .rst(rst),

                .in(in[i]),
                .in_delayed(in_delayed[i])
            );
        end
    endgenerate
endmodule

`endif
