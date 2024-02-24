`ifndef __DELAY_REGISTER_V__
`define __DELAY_REGISTER_V__

module delay_register (
    input clk,
    input rst,

    input in,
    output reg in_delayed
);

    always @(posedge clk)
        if (rst) in_delayed <= 1'b0;
        else in_delayed <= in;

endmodule

`endif
