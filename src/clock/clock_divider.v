/**
 * Clock divider that is posedge sensitive, with no output synchronization.
 */
module clock_divider #(
    parameter integer NUM_STAGES = 7
) (
    input clk,
    input rst,

    output clk_div
);
    // My original code was:
    // generate
    // frequency_divider_stage frequency_divider_stage_inst (
    //     .clk_in(i == 0 ? clk : clk_divs[i-1]),
    //     .rst(rst),
    //     .clk_out(i == NUM_STAGES - 1 ? clk_div : clk_divs[i])
    // );
    // endgenerate
    // But apparently, the conditional operator is not synthesizable.
    // That's why I'm using the following code instead.

    genvar i;
    generate
        for (i = 0; i < NUM_STAGES; i = i + 1) begin : gen_clock_divider_stage
            wire in;

            if (i == 0) assign in = clk;
            else assign in = gen_clock_divider_stage[i-1].out;

            wire out;

            frequency_divider_stage frequency_divider_stage_inst (
                .clk_in(in),
                .rst(rst),
                .clk_out(out)
            );

            if (i == NUM_STAGES - 1) begin : gen_assign_clk_div_in_last_stage
                assign clk_div = out;
            end
        end
    endgenerate

endmodule
