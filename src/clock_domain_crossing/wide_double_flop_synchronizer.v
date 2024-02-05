module wide_double_flop_synchronizer #(
    parameter integer WIDTH = 8,
    parameter integer AT_POSEDGE_RST = 1
) (
    input clk,
    input rst,

    input enable,

    input  [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_wide_double_flop_synchronizer
            double_flop_synchronizer #(
                .AT_POSEDGE_RST(AT_POSEDGE_RST)
            ) double_flop_synchronizer_inst (
                .clk(clk),
                .rst(rst),

                .enable(enable),

                .in (in[i]),
                .out(out[i])
            );
        end
    endgenerate

endmodule
