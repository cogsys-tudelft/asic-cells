// Frequency-divider stage (posedge sensitive)
module frequency_divider_stage (
    input clk_in,
    input rst,
    output reg clk_out
);

    always @(posedge clk_in, posedge rst) begin
        if (rst) clk_out <= 1'b0;
        else clk_out <= ~clk_out;
    end

endmodule
