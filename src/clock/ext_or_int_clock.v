/**
 * Separate clock OR module for easier SDC constraints definition
 */
module ext_or_int_clock (
    input  clk_ext,
    input  clk_int,
    output clk
);
    assign clk = clk_ext | clk_int;

endmodule
