/**
 * We do not use an enable signal for the SPI client, as that enable signal would be clocked on the
 * internal clock domain, causing issues with the logic that is clocked on the external SPI clock.
 * Instead what we do is, send out a in_idle signal via a separate wire. When this signal is high,
 * the SPI server knows that the SPI client will respond. When this signal is low, the SPI server
 * should not drive the external clock nor the MOSI line.
 */
module spi_client #(
    parameter integer MESSAGE_BIT_WIDTH = 32,
    parameter integer CODE_BIT_WIDTH = 4,
    parameter integer START_ADDRESS_BIT_WIDTH = 16,
    localparam integer NumTransactionsBitWidth = MESSAGE_BIT_WIDTH - CODE_BIT_WIDTH - START_ADDRESS_BIT_WIDTH - 1
) (
    input rst_async,

    input  SCK,
    output MISO,
    input  MOSI,

    input clk,
    input rst,

    input enable_configuration,

    output [CODE_BIT_WIDTH-1:0] code,
    output reg [START_ADDRESS_BIT_WIDTH-1:0] current_address,

    input [MESSAGE_BIT_WIDTH-1:0] MISO_data,
    output reg [MESSAGE_BIT_WIDTH-1:0] MOSI_data,

    output config_data_ready,
    output [START_ADDRESS_BIT_WIDTH-1:0] current_config_address,
    output [MESSAGE_BIT_WIDTH-1:0] config_data,

    output write_new,
    output read_sync
);

    // Local parameters ---------------------------------------------------------------------------

    localparam integer WithinMessageCounterBitWidth = $clog2(MESSAGE_BIT_WIDTH);
    localparam integer SpiCounterBitWidth = NumTransactionsBitWidth + WithinMessageCounterBitWidth;

    // Check parameters ---------------------------------------------------------------------------

    if (NumTransactionsBitWidth < 0) begin
        ERROR__MESSAGE_BIT_WIDTH_must_be_at_least_CODE_BIT_WIDTH_plus_START_ADDRESS_BIT_WIDTH_plus_1 a ();
    end else if (2 ** $clog2(MESSAGE_BIT_WIDTH) != MESSAGE_BIT_WIDTH) begin
        ERROR__MESSAGE_BIT_WIDTH_must_be_a_power_of_two a ();
    end else if (NumTransactionsBitWidth > START_ADDRESS_BIT_WIDTH) begin
        ERROR__NumTransactionsBitWidth_must_be_less_than_or_equal_to_START_ADDRESS_BIT_WIDTH a ();
    end

    // Registers ----------------------------------------------------------------------------------

    reg [SpiCounterBitWidth-1:0] spi_counter;  // TODO: why not START_ADDRESS_BIT_WIDTH-1?
    reg [MESSAGE_BIT_WIDTH-1:0] spi_shift_reg_out, spi_shift_reg_in;
    reg [MESSAGE_BIT_WIDTH-1:0] instruction_message;  // Format of the message: read(1)/write(0) | code | start_address | num_transactionss

    reg MOSI_data_ready;
    reg load_MISO_data;

    // Wires for combinational logic --------------------------------------------------------------

    wire [WithinMessageCounterBitWidth-1:0] within_message_counter;
    wire [NumTransactionsBitWidth-1:0] transaction_counter;

    wire message_complete;
    wire received_instruction_message;
    wire [NumTransactionsBitWidth-1:0] num_transactions, num_transactions_from_message;
    wire at_least_one_data_message;  // At least one complete message with data has been received
    wire [MESSAGE_BIT_WIDTH-1:0] new_shift_reg_out;
    wire within_message_counter_zero;

    wire [START_ADDRESS_BIT_WIDTH-1:0] start_address;
    wire read;
    wire write;

    // Combinational logic ------------------------------------------------------------------------

    assign {transaction_counter, within_message_counter} = spi_counter;

    assign {read, code, start_address, num_transactions_from_message} = instruction_message;
    assign write = ~read;

    assign message_complete = &within_message_counter;  // If the last WithinMessageCounterBitWidth bits are all 1, then the message is completely written
    assign received_instruction_message = spi_counter == MESSAGE_BIT_WIDTH - 1;
    assign num_transactions = received_instruction_message ? spi_shift_reg_in[NumTransactionsBitWidth-1:0] : num_transactions_from_message;
    assign at_least_one_data_message = |transaction_counter;
    assign new_shift_reg_out = {spi_shift_reg_out[MESSAGE_BIT_WIDTH-2:0], 1'b0};
    assign within_message_counter_zero = ~|within_message_counter;

    // Internal modules ---------------------------------------------------------------------------

    spi_clock_barrier_crossing spi_clock_barrier_crossing_inst (
        .clk(clk),
        .rst(rst),

        .enable_configuration(enable_configuration),
        .MOSI_data_ready(MOSI_data_ready),
        .load_MISO_data(load_MISO_data),

        .write_new(write_new),
        .read_sync(read_sync)
    );

    // Sequential logic ---------------------------------------------------------------------------

    // SPI counter
    always @(negedge SCK, posedge rst_async) begin
        if (rst_async) begin
            spi_counter <= 0;
            // If 32 SPI clockcycles have passed and the total number of words has been written
        end else if (message_complete && (transaction_counter >= num_transactions)) begin
            spi_counter <= 0;
        end else begin
            spi_counter <= spi_counter + 1;
        end
    end

    // Write message to local register if full message ready
    always @(negedge SCK, posedge rst_async) begin
        if (rst_async) begin
            instruction_message <= 0;
        end else if (received_instruction_message) begin
            instruction_message <= spi_shift_reg_in;
        end
    end

    always @(posedge SCK) begin
        spi_shift_reg_in <= {spi_shift_reg_in[MESSAGE_BIT_WIDTH-2:0], MOSI};
    end

    always @(negedge SCK, posedge rst_async) begin
        if (rst_async) begin
            spi_shift_reg_out <= 0;

            load_MISO_data <= 0;
            MOSI_data_ready <= 0;
            // If the main has sent one complete data message, write the data to the output register
        end else if (write && message_complete && at_least_one_data_message) begin
            spi_shift_reg_out <= 0;
            current_address <= start_address + transaction_counter - 1;
            MOSI_data <= spi_shift_reg_in;

            MOSI_data_ready <= 1;
            // If we have just received a new read instruction
        end else if (spi_shift_reg_in[MESSAGE_BIT_WIDTH-1] && received_instruction_message) begin
            spi_shift_reg_out <= new_shift_reg_out;
            current_address <= spi_shift_reg_in[START_ADDRESS_BIT_WIDTH+NumTransactionsBitWidth-1:NumTransactionsBitWidth];

            load_MISO_data <= 1;
            // If the main just received a complete data message and we stil have more transactions to do
        end else if (read && message_complete && at_least_one_data_message && (transaction_counter < num_transactions)) begin
            current_address <= start_address + transaction_counter;

            load_MISO_data <= 1;
            // If we are in the first clockcycle after receiving the complete instruction message and we are reading from client to main
        end else if (read && within_message_counter_zero && at_least_one_data_message) begin
            spi_shift_reg_out <= MISO_data << 1;

            load_MISO_data <= 0;
            MOSI_data_ready <= 0;
        end else if (within_message_counter_zero) begin
            MOSI_data_ready <= 0;
        end else begin
            spi_shift_reg_out <= new_shift_reg_out;
        end
    end

    assign MISO = (read && within_message_counter_zero && at_least_one_data_message) ? MISO_data[MESSAGE_BIT_WIDTH-1] : spi_shift_reg_out[MESSAGE_BIT_WIDTH-1];

    // We continuously assign these signals for the config memory, as we want the config module to write data to its
    // internal registers on the posedge of the clock. This because, at the point MOSI_data_ready is high, 
    // MESSAGE_BIT_WIDTH clockcycles have passed and so there will never be a positive or negative edge anymore to
    // trigger the config memory to write the data into its internal registers.
    assign config_data_ready = write && (code == 0) && message_complete && at_least_one_data_message;
    assign current_config_address = start_address + transaction_counter - 1;
    assign config_data = {spi_shift_reg_in[MESSAGE_BIT_WIDTH-2:0], MOSI};

endmodule
