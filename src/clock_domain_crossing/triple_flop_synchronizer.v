`ifndef __TRIPLE_FLOP_SYNCHRONIZER_V__
`define __TRIPLE_FLOP_SYNCHRONIZER_V__

module triple_flop_synchronizer #(
    parameter integer AT_POSEDGE_RST = 1
) (
    input clk,
    input rst,

    input enable,

    input in,
    output reg out
);

    wire in_sync;

    double_flop_synchronizer #(
        .AT_POSEDGE_RST(AT_POSEDGE_RST)
    ) double_flop_synchronizer_inst (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .in(in),
        .out(in_sync)
    );

    // Unfortunately, the approach below is the only way to create synthesizable
    // Verilog code. It is not possible to only generate the always @ (...) part.
    generate
        if (AT_POSEDGE_RST == 1) begin : gen_if_at_posedge_rst
            always @(posedge clk, posedge rst) begin
                if (rst) begin
                    out <= 0;
                end else if (enable) begin
                    out <= in_sync;
                end
            end
        end else begin : gen_if_regular_rst
            always @(posedge clk) begin
                if (rst) begin
                    out <= 0;
                end else if (enable) begin
                    out <= in_sync;
                end
            end
        end
    endgenerate

endmodule

`endif
