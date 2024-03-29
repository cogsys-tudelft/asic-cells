`ifndef __DOUBLE_FLOP_SYNCHRONZER_V__
`define __DOUBLE_FLOP_SYNCHRONZER_V__

/**
 * Use this module only for clock domain crossing or for creating a synchronous
 * input from an asynchronous input signal (into a chip). For regular double delays
 * via a register, `double_delay_register.v` should be used.
 */
module double_flop_synchronizer #(
    parameter integer AT_POSEDGE_RST = 1
) (
    input clk,
    input rst,

    input enable,

    input in,
    output reg out
);

    // Prefixed and suffixed with __ to make sure the structural simulation in QuestaSim
    // can handle the clock-domain crossing.
    reg __intermediate__;

    // Unfortunately, the approach below is the only way to create synthesizable
    // Verilog code. It is not possible to only generate the always @ (...) part.
    generate
        if (AT_POSEDGE_RST == 1) begin : gen_if_at_posedge_rst
            always @(posedge clk, posedge rst) begin
                if (rst) begin
                    __intermediate__ <= 1'b0;
                    out <= 1'b0;
                end else if (enable) begin
                    __intermediate__ <= in;
                    out <= __intermediate__;
                end
            end
        end else begin : gen_if_regular_rst
            always @(posedge clk) begin
                if (rst) begin
                    __intermediate__ <= 1'b0;
                    out <= 1'b0;
                end else if (enable) begin
                    __intermediate__ <= in;
                    out <= __intermediate__;
                end
            end
        end
    endgenerate

endmodule

`endif
