`ifndef __DOUBLE_DELAY_REGISTER_V__
`define __DOUBLE_DELAY_REGISTER_V__

`include "delay_register.v"

module double_delay_register (
    input clk,
    input rst,

    input in,
    output reg in_delayed
);

    wire in_delayed_delayed;

    delay_register delay_register_inst_1 (
        .clk(clk),
        .rst(rst),

        .in(in),
        .in_delayed(in_delayed_delayed)
    );

    delay_register delay_register_inst_2 (
        .clk(clk),
        .rst(rst),

        .in(in_delayed_delayed),
        .in_delayed(in_delayed)
    );
endmodule

`endif
