`ifndef __MEMORY_MANAGER_V__
`define __MEMORY_MANAGER_V__

/**
 * Code of this module is a generalization of:
 * https://github.com/ChFrenkel/ReckOn/blob/5e5c0bea8fe1897876ba3b7bfdcecf76d3bf4505/src/srnn.v#L1260
 *
 * If you want to use this memory manager for dual port memories (which have parallel read and write
 * capabilities), then pass your control_read_enable signal to the control_chip_select signal and pass
 * the control_read_address to the control_address signal. Then, to control your memory, use the
 * write_enable and read_enable signals. To switch between writing from the memory manager and writing
 * from the main core, use the program_this_memory_new signal.
*/
module memory_manager #(
    parameter integer WORD_BIT_WIDTH = 64,
    parameter integer ADDRESS_BIT_WIDTH = 9,
    parameter integer START_ADDRESS_BIT_WIDTH = 14,
    parameter integer MESSAGE_BIT_WIDTH = 32
) (
    input program_memory_new,
    input read_memory_sync,
    input is_code_for_this_memory,

    input [START_ADDRESS_BIT_WIDTH-1:0] spi_address,
    input [MESSAGE_BIT_WIDTH-1:0] spi_data_in,
    output [MESSAGE_BIT_WIDTH-1:0] spi_data_out,

    input [WORD_BIT_WIDTH-1:0] memory_data_out,

    input control_chip_select,
    input control_write_enable,
    input global_power_down,
    input [ADDRESS_BIT_WIDTH-1:0] control_address,
    input [WORD_BIT_WIDTH-1:0] control_data_in,
    input [WORD_BIT_WIDTH-1:0] control_mask,

    output chip_select,
    output write_enable,
    output read_enable,
    output program_this_memory_new,
    output [ADDRESS_BIT_WIDTH-1:0] address,
    output [WORD_BIT_WIDTH-1:0] data_in,
    output [WORD_BIT_WIDTH-1:0] mask
);

    // Local parameters ---------------------------------------------------------------------------

    localparam REQUIRED_SHIFT = $clog2(MESSAGE_BIT_WIDTH);
    localparam NUM_ZEROES = WORD_BIT_WIDTH - MESSAGE_BIT_WIDTH;
    localparam NUM_MESSAGES_IN_WORD = (WORD_BIT_WIDTH + MESSAGE_BIT_WIDTH - 1) / MESSAGE_BIT_WIDTH;  // Round-up division
    localparam BITS_FOR_WITHIN_ROW = $clog2(NUM_MESSAGES_IN_WORD);
    localparam SHIFT_BIT_WIDTH = BITS_FOR_WITHIN_ROW + REQUIRED_SHIFT;

    // Check parameters ---------------------------------------------------------------------------

    if (NUM_MESSAGES_IN_WORD != WORD_BIT_WIDTH / MESSAGE_BIT_WIDTH) begin
        // TODO: make memory manager also work for non-perfectly divisible widths
        ERROR__WIDTH_must_be_perfectly_divisible_by_MESSAGE_BIT_WIDTH a ();
    end else if (ADDRESS_BIT_WIDTH + BITS_FOR_WITHIN_ROW > START_ADDRESS_BIT_WIDTH) begin
        ERROR__ADDRESS_BIT_WIDTH_plus_BITS_FOR_WITHIN_ROW_must_be_less_than_or_equal_to_START_ADDRESS_BIT_WIDTH a ();
    end else if (START_ADDRESS_BIT_WIDTH < ADDRESS_BIT_WIDTH + BITS_FOR_WITHIN_ROW) begin
        ERROR__START_ADDRESS_BIT_WIDTH_must_be_at_least_ADDRESS_BIT_WIDTH_plus_BITS_FOR_WITHIN_ROW a ();
    end

    // Wires --------------------------------------------------------------------------------------

    wire read_this_memory_sync;

    wire [BITS_FOR_WITHIN_ROW-1:0] within_row_address;
    wire [ADDRESS_BIT_WIDTH-1:0] row_address;
    wire [SHIFT_BIT_WIDTH-1:0] amount_to_shift;

    wire [NUM_ZEROES-1:0] zeroes;

    wire [WORD_BIT_WIDTH-1:0] data_out_full;

    // Combinational logic ------------------------------------------------------------------------

    assign program_this_memory_new = program_memory_new && is_code_for_this_memory;
    assign read_this_memory_sync = read_memory_sync && is_code_for_this_memory;

    assign within_row_address = spi_address[BITS_FOR_WITHIN_ROW-1:0];
    assign row_address = spi_address[BITS_FOR_WITHIN_ROW+ADDRESS_BIT_WIDTH-1:BITS_FOR_WITHIN_ROW];
    assign amount_to_shift = {{REQUIRED_SHIFT{1'b0}}, within_row_address} << REQUIRED_SHIFT;

    assign zeroes = {NUM_ZEROES{1'b0}};

    // Chip-select should be low when power-down is high
    assign chip_select = program_this_memory_new | read_this_memory_sync ? 1'b1 : (control_chip_select & ~global_power_down);
    assign read_enable = read_this_memory_sync ? 1'b1 : (control_chip_select & ~global_power_down);
    assign write_enable = program_this_memory_new ? 1'b1 : (read_this_memory_sync ? 1'b0 : (control_write_enable & ~global_power_down));
    assign address = program_this_memory_new | read_this_memory_sync ? row_address : control_address;
    assign data_in = program_this_memory_new ? {zeroes, spi_data_in} << amount_to_shift : control_data_in;
    assign mask = program_this_memory_new ? {zeroes, {MESSAGE_BIT_WIDTH{1'b1}}} << amount_to_shift : control_mask;

    // Unfortunately can't do take [MESSAGE_BIT_WIDTH-1:0] bits together with the shifting in one line of code...
    assign data_out_full = memory_data_out >> amount_to_shift;
    assign spi_data_out = data_out_full[MESSAGE_BIT_WIDTH-1:0];

endmodule

`endif
