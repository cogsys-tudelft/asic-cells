`ifndef __TRIPLE_TOGGLE_BARRIER_V__
`define __TRIPLE_TOGGLE_BARRIER_V__

`include "double_latching_barrier.v"

module triple_toggle_barrier
    (
        input clk,
        input rst,

        input enable,

        input in,
        output out
    );

    wire in_sync;

    double_latching_barrier double_latching_barrier_inst (
        .clk(clk), .rst(rst), .enable(enable),
        .in(in), .out(in_sync)
    );

    reg in_delete;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            in_delete <= 0;
        end else if (enable) begin
            in_delete <= in_sync;
        end
    end

    assign out = in_sync & ~in_delete;

endmodule

`endif
