`ifndef __DOUBLE_LATCHING_BARRIER_V__
`define __DOUBLE_LATCHING_BARRIER_V__

module double_latching_barrier
    #(parameter WIDTH = 1)
    (
        input clk,
        input rst,

        input enable,

        input [WIDTH-1:0] in,
        output reg [WIDTH-1:0] out
    );

    reg [WIDTH-1:0] intermediate;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            intermediate <= 0;
            out <= 0;
        end else if (enable) begin
            intermediate <= in;
            out <= intermediate;
        end
    end
endmodule

`endif
