`ifndef __CUSTOM_CLOCK_WITH_PHASE_GENERATOR_V__
`define __CUSTOM_CLOCK_WITH_PHASE_GENERATOR_V__

module custom_clock_with_phase_generator
    #(parameter integer CYCLE_WIDTH = 16)
    (
        input arst,
        input clk_in,
        input enable,
        input [CYCLE_WIDTH-1:0] high_phase_cycles,
        input [CYCLE_WIDTH-1:0] low_phase_cycles,
        output reg clk_out
    );

    reg [CYCLE_WIDTH-1:0] counter, max_count;

    always @(posedge clk_in, posedge arst) begin
        if (arst) begin
            counter <= 0;
            max_count <= low_phase_cycles;
            clk_out <= 1'b0;
        // Make sure that the clock generator is not running unnecessarily
        end else if (enable) begin
            if (counter == cycles) begin
                counter <= 0;
                max_count <= (max_count == low_phase_cycles) ? high_phase_cycles : low_phase_cycles;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule

`endif