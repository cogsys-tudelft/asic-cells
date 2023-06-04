`include "config_memory.sv"
`include "managed_weight_memory.v"
`include "spi_client.sv"
`include "spi_clock_barrier_crossing.v"
`include "pointers.v"

module skeleton
    (
        input clk_ext,
        input rst_async,
        input enable_clk_int,

        input SCK,
        output MISO,
        input MOSI,

        output clk_int_div,

        input [HIGH_SPEED_IN_PINS-1:0] data_in,
        input in_request,
        output out_acknowledge,

        output [HIGH_SPEED_OUT_PINS-1:0] data_out,
        output out_request,
        input in_acknowledge
    );

    // ============================================================================================
    // Configuration parameters
    // ============================================================================================

    localparam MESSAGE_BIT_WIDTH = 32;
    localparam CODE_BIT_WIDTH = 4;
    localparam START_ADDRESS_BIT_WIDTH = 16; // TODO: rename this parameter

    // ============================================================================================
    // Wires and registers
    // ============================================================================================

    // Clock and reset wires ----------------------------------------------------------------------

    wire clk, clk_int;
    wire rst_sync;

    wire clk_div_in;
    wire clk_div_out;

    // SPI client wires ---------------------------------------------------------------------------

    wire [CODE_BIT_WIDTH-1:0] code;

    wire [START_ADDRESS_BIT_WIDTH-1:0] spi_address;

    reg [MESSAGE_BIT_WIDTH-1:0] in_message;
    wire load_new_in_message;
    wire [MESSAGE_BIT_WIDTH-1:0] spi_out_message;
    wire spi_out_message_ready;

    // Wires per code -----------------------------------------------------------------------------

    // 0: config (not readable)
    // 0: pointers (not writable)
    wire code_is_pointers = (code == 0);
    wire code_is_weight = (code == 1);

    // SPI clock barrier crossing wires ------------------------------------------------------------

    // TODO: give these two signals better names
    wire write_new;
    wire read_sync;

    // Config memory wires ------------------------------------------------------------------------

    wire config_message_ready;
    wire [START_ADDRESS_BIT_WIDTH-1:0] spi_config_address;
    wire [MESSAGE_BIT_WIDTH-1:0] spi_out_config_message;

    // Pointers wires -----------------------------------------------------------------------------

    wire [MESSAGE_BIT_WIDTH-1:0] pointers_spi_data_out;

    // Weight memory wires ------------------------------------------------------------------------

    wire [WEIGHT_ADDRESS_WIDTH - 1:0] weight_control_address;
    wire [WEIGHT_WORD_BIT_WIDTH - 1:0] weight_control_data_in;
    wire [WEIGHT_WORD_BIT_WIDTH - 1:0] weight_data_out;
    wire [WEIGHT_WORD_BIT_WIDTH - 1:0] weight_control_mask;
    wire weight_control_chip_select;
    wire weight_control_write_enable;

    wire [MESSAGE_BIT_WIDTH-1:0] weight_spi_data_out;

    // ============================================================================================
    // Modules
    // ============================================================================================

    // Make external asynchronous reset synchronous with the internal clock
    double_latching_barrier double_latching_barrier_rst (
        .clk(clk),
        .rst(1'b0),

        .enable(1'b1),

        .in(rst_async),
        .out(rst_sync)
    );

    // FSM ----------------------------------------------------------------------------------------

    wire enable_processing_sync;

    double_latching_barrier double_latching_barrier_enable_processing (
        .clk(clk),
        .rst(rst_sync),

        .enable(1'b1),

        .in(cfg.enable_processing),
        .out(enable_processing_sync)
    );

    fsm fsm_inst (
        .clk(clk),
        .rst(rst_sync),

        .enable_processing_sync(enable_processing_sync),
        .start_sending(start_sending),
        .done_sending(done_sending),

        .state(state)
    );

    // SPI client --------------------------------------------------------------------------------

    spi_client #(
        .MESSAGE_BIT_WIDTH(MESSAGE_BIT_WIDTH),
        .CODE_BIT_WIDTH(CODE_BIT_WIDTH),
        .START_ADDRESS_BIT_WIDTH(START_ADDRESS_BIT_WIDTH)
    ) spi_client_inst (
        .RST_async(rst_async),
        .SCK(SCK),
        .MISO(MISO),
        .MOSI(MOSI),

        .code(code),
        .current_address(spi_address),

        .in_message(in_message),
        .load_new_in_message(load_new_in_message),

        .out_message(spi_out_message),
        .out_message_ready(spi_out_message_ready),

        .config_message_ready(config_message_ready),
        .current_config_address(spi_config_address),
        .out_config_message(spi_out_config_message)
    );

    spi_clock_barrier_crossing spi_clock_barrier_crossing_inst (
        .clk(clk),
        .rst(rst_sync),

        .enable_configuration(state == `IDLE),
        .out_message_ready(spi_out_message_ready),
        .load_new_in_message(load_new_in_message),

        .write_new(write_new),
        .read_sync(read_sync)
    );

    // TODO: we now have one out message register per memory, could we use one for all?
    always @(posedge clk) begin
        // We are now writing multiple clockcyles to in_message as read_sync stays high for multiple clock cycles
        // in the clk clock domain (while only 1 in the SCK domain).
        // TODO: is this necessary or can we use the same approach as for write_new (only high for one clk cycle)?
        if (read_sync) begin
            if (code_is_pointers) begin
                in_message <= pointers_spi_data_out;
            end if (code_is_weight) begin
                in_message <= weight_spi_data_out;
            end else if (code_is_bias) begin
                in_message <= bias_spi_data_out;
            end
        end
    end

    // Config memory ------------------------------------------------------------------------------

    config_memory #(
        .MESSAGE_BIT_WIDTH(MESSAGE_BIT_WIDTH),
        .START_ADDRESS_BIT_WIDTH(START_ADDRESS_BIT_WIDTH),

        .MODE_BIT_WIDTH(MODE_BIT_WIDTH),
        .BLOCKS_WIDTH(BLOCKS_WIDTH),
        .BLOCKS_KERNEL_WIDTH(BLOCKS_KERNEL_WIDTH),
        .CUMSUM_WIDTH(CUMSUM_WIDTH),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .LAYER_WIDTH(LAYER_WIDTH)
    ) cfg (
        .SCK(SCK),
        .RST_async(rst_async),

        .config_message_ready(config_message_ready),
        .spi_config_address(spi_config_address), // TODO: can reduce the address bitwidth accordingly here
        .config_spi_data_in(spi_out_config_message)
    );

    // Pointers -----------------------------------------------------------------------------------

    pointers #(
        .MESSAGE_BIT_WIDTH(MESSAGE_BIT_WIDTH),
        .START_ADDRESS_BIT_WIDTH(START_ADDRESS_BIT_WIDTH)
    ) pointers_inst (
        .clk(clk),

        .read_sync(read_sync),
        .code_is_pointers(code_is_pointers),

        .spi_address(spi_address),
        .pointer_spi_data_out(pointers_spi_data_out)
    );

    // Weight memory ------------------------------------------------------------------------------

    // The weight memory needs to be active in the first cycle when the PE array control is enabled,
    // as its outputs are the the 0th step addresses, but also should remain active one cycle longer
    // than the PE array control, since when the enable signal goes low, also the last address of the
    // controller will be outputed, which we still need to process.
    assign weight_control_chip_select = enable_pe_control;
    assign weight_control_write_enable = 0;

    managed_weight_memory #(
        .WEIGHT_WORD_BIT_WIDTH(WEIGHT_WORD_BIT_WIDTH),
        .WEIGHT_ROWS(WEIGHT_ROWS),
        .START_ADDRESS_BIT_WIDTH(START_ADDRESS_BIT_WIDTH),
        .MESSAGE_BIT_WIDTH(MESSAGE_BIT_WIDTH)
    ) managed_weight_memory_inst (
        .clk(clk),

        .write_new(write_new),
        .read_sync(read_sync),
        .code_is_weight(code_is_weight),

        .spi_address(spi_address),
        .weights_spi_data_in(spi_out_message),
        .weight_spi_data_out(weight_spi_data_out),

        .weight_control_chip_select(weight_control_chip_select),
        .weight_control_write_enable(weight_control_write_enable),
        .weight_control_address(weight_control_address),
        .weight_control_data_in(weight_control_data_in),
        .weight_control_mask(weight_control_mask),

        .weight_data_out(weight_data_out)
    );

endmodule