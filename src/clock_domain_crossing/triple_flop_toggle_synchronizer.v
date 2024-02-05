`ifndef __TRIPLE_FLOP_TOGGLE_SYNCHRONIZER_V__
`define __TRIPLE_FLOP_TOGGLE_SYNCHRONIZER_V__

module triple_flop_toggle_synchronizer #(
    parameter bool AT_POSEDGE_RST = 1
) (
    input clk,
    input rst,

    input enable,

    input  in,
    output out
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

    reg in_delete;

    // Unfortunately, the approach below is the only way to create synthesizable
    // Verilog code. It is not possible to only generate the always @ (...) part.
    generate
        if (AT_POSEDGE_RST == 1) begin : gen_if_at_posedge_rst
            always @(posedge clk, posedge rst) begin
                if (rst) begin
                    in_delete <= 0;
                end else if (enable) begin
                    in_delete <= in_sync;
                end
            end
        end else begin : gen_if_regular_rst
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
