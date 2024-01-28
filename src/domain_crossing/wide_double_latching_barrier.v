`include "double_latching_barrier.v"

module wide_double_latching_barrier #(
    parameter int WIDTH = 8,
    parameter bool AT_POSEDGE_RST = 1
) (
    input clk,
    input rst,

    input enable,

    input  [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_wide_double_latching_barrier
            double_latching_barrier #(
                .AT_POSEDGE_RST(AT_POSEDGE_RST)
            ) double_latching_barrier_inst (
                .clk(clk),
                .rst(rst),

                .enable(enable),

                .in (in[i]),
                .out(out[i])
            );
        end
    endgenerate

endmodule
