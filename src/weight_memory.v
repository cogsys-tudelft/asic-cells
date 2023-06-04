`include "generic_single_port_tsmc_sram.sv"

module weight_memory
    #(parameter WIDTH = 1024, parameter NUM_ROWS = 128, localparam ADDRESS_WIDTH = $clog2(NUM_ROWS))
    (
        input clk,
        
        input [ADDRESS_WIDTH-1:0] address,
        input [WIDTH-1:0] data_in,
        input [WIDTH-1:0] mask,
        input chip_select,
        input write_enable,

        output [WIDTH-1:0] data_out
    );

    generic_single_port_tsmc_sram #(
        .WIDTH(WIDTH),
        .NUM_ROWS(NUM_ROWS)
    ) generic_single_port_tsmc_sram_inst (
        .CLK(clk),
        .CEB(chip_select),
        .WEB(write_enable),
        .A(address),
        .D(data_in),
        .M(mask),
        .Q(data_out)
    );

endmodule
