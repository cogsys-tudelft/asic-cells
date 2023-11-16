`ifndef __TRIPLE_TOGGLE_BARRIER_V__
`define __TRIPLE_TOGGLE_BARRIER_V__

`include "double_latching_barrier.v"

module triple_toggle_barrier
    #(parameter AT_POSEDGE_RST = 1)
    (
        input clk,
        input rst,

        input enable,

        input in,
        output out
    );

    wire in_sync;

    double_latching_barrier #(
        .AT_POSEDGE_RST(AT_POSEDGE_RST)
    ) double_latching_barrier_inst (
        .clk(clk), .rst(rst), .enable(enable),
        .in(in), .out(in_sync)
    );

    reg in_delete;

    // Unfortunately, the approach below is the only way to create synthesizable
    // Verilog code. It is not possible to only generate the always @ (...) part.
    generate
        if (AT_POSEDGE_RST == 1) begin
            always @(posedge clk, posedge rst) begin
                if (rst) begin
                    in_delete <= 0;
                end else if (enable) begin
                    in_delete <= in_sync;
                end
            end
        end else begin
            always @(posedge clk) begin
                if (rst) begin
                    in_delete <= 0;
                end else if (enable) begin
                    in_delete <= in_sync;
                end
            end
        end
    endgenerate

    assign out = in_sync & ~in_delete;

endmodule

`endif
