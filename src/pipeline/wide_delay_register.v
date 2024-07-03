`ifndef __WIDE_DELAY_REGISTER_V__
`define __WIDE_DELAY_REGISTER_V__

module wide_delay_register #(
    parameter integer WIDTH = 8
) (
    input clk,
    input rst,

    input  [WIDTH-1:0] in,
    output [WIDTH-1:0] in_delayed
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_wide_delay_register
            delay_register delay_register_inst (
                .clk(clk),
                .rst(rst),

                .in(in[i]),
                .in_delayed(in_delayed[i])
            );
        end
    endgenerate
endmodule

`endif
