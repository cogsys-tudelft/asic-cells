module spi_client
    #(
        parameter MESSAGE_BIT_WIDTH = 32,
        parameter CODE_BIT_WIDTH = 4,
        parameter START_ADDRESS_BIT_WIDTH = 16,
        localparam NUM_TRANSACTIONS_BIT_WIDTH = MESSAGE_BIT_WIDTH - CODE_BIT_WIDTH - START_ADDRESS_BIT_WIDTH - 1
    )(
        input wire RST_async,

        input wire SCK,
        output wire MISO,
        input wire MOSI,

        output [CODE_BIT_WIDTH-1:0] code,
        output reg [START_ADDRESS_BIT_WIDTH-1:0] current_address,

        input wire [MESSAGE_BIT_WIDTH-1:0] in_message,
        output reg load_new_in_message, // TODO: maybe rename this and
        output reg [MESSAGE_BIT_WIDTH-1:0] out_message,
        output reg out_message_ready, // TODO: maybe rename this register

        output config_message_ready,
        output [START_ADDRESS_BIT_WIDTH-1:0] current_config_address,
        output [MESSAGE_BIT_WIDTH-1:0] out_config_message
    );

    // Local parameters ---------------------------------------------------------------------------

    localparam WITHIN_MESSAGE_COUNTER_BIT_WIDTH = $clog2(MESSAGE_BIT_WIDTH);
    localparam SPI_COUNTER_BIT_WIDTH = NUM_TRANSACTIONS_BIT_WIDTH + WITHIN_MESSAGE_COUNTER_BIT_WIDTH;

    // Check parameters ---------------------------------------------------------------------------

    if (NUM_TRANSACTIONS_BIT_WIDTH < 0) begin
        ERROR__MESSAGE_BIT_WIDTH_must_be_at_least_CODE_BIT_WIDTH_plus_START_ADDRESS_BIT_WIDTH_plus_1();
    end else if(2**$clog2(MESSAGE_BIT_WIDTH) != MESSAGE_BIT_WIDTH) begin
        ERROR__MESSAGE_BIT_WIDTH_must_be_a_power_of_two();
    end

    // Registers ----------------------------------------------------------------------------------

    reg [SPI_COUNTER_BIT_WIDTH-1:0] spi_counter; // TODO: why not START_ADDRESS_BIT_WIDTH-1?
    reg [MESSAGE_BIT_WIDTH-1:0] spi_shift_reg_out, spi_shift_reg_in;
    reg [MESSAGE_BIT_WIDTH-1:0] instruction_message; // Format of the message: read(1)/write(0) | code | start_address | num_transactionss

    // Wires for combinational logic --------------------------------------------------------------

    wire [WITHIN_MESSAGE_COUNTER_BIT_WIDTH-1:0] within_message_counter;
    wire [NUM_TRANSACTIONS_BIT_WIDTH-1:0] transaction_counter;

    wire message_complete;
    wire received_instruction_message;
    wire [NUM_TRANSACTIONS_BIT_WIDTH-1:0] num_transactions;
    wire at_least_one_data_message; // At least one complete message with data has been received
    wire [MESSAGE_BIT_WIDTH-1:0] new_shift_reg_out;
    wire within_message_counter_zero;

    wire [START_ADDRESS_BIT_WIDTH-1:0] start_address;
    wire read;
    wire write;

    // Combinational logic ------------------------------------------------------------------------

    assign within_message_counter = spi_counter[WITHIN_MESSAGE_COUNTER_BIT_WIDTH-1:0];
    assign transaction_counter = spi_counter[SPI_COUNTER_BIT_WIDTH-1:WITHIN_MESSAGE_COUNTER_BIT_WIDTH];

    assign message_complete = &within_message_counter; // If the last WITHIN_MESSAGE_COUNTER_BIT_WIDTH bits are all 1, then the message is completely written
    assign received_instruction_message = spi_counter == MESSAGE_BIT_WIDTH - 1;
    assign num_transactions = received_instruction_message ? spi_shift_reg_in[NUM_TRANSACTIONS_BIT_WIDTH-1:0] : instruction_message[NUM_TRANSACTIONS_BIT_WIDTH-1:0];
    assign at_least_one_data_message = |transaction_counter;
    assign new_shift_reg_out = {spi_shift_reg_out[MESSAGE_BIT_WIDTH-2:0], 1'b0};
    assign within_message_counter_zero = ~|within_message_counter;
    
    assign code = instruction_message[MESSAGE_BIT_WIDTH-2 -: CODE_BIT_WIDTH]; // TODO check if this correct
    assign start_address = instruction_message[START_ADDRESS_BIT_WIDTH+NUM_TRANSACTIONS_BIT_WIDTH-1:NUM_TRANSACTIONS_BIT_WIDTH];
    assign read = instruction_message[MESSAGE_BIT_WIDTH-1];
    assign write = ~read;

    // Sequential logic ---------------------------------------------------------------------------

    // SPI counter
    always @(negedge SCK, posedge RST_async) begin
        if (RST_async) begin
            spi_counter <= 0;
        // If 32 SPI clockcycles have passed and the total number of words has been written
        end else if (message_complete && (transaction_counter >= num_transactions)) begin
            spi_counter <= 0;
        end else begin
            spi_counter <= spi_counter + 1;
        end
    end

    // Write message to local register if full message ready
    always @(negedge SCK, posedge RST_async) begin
        if (RST_async) begin
            instruction_message <= 0;
        end else if (received_instruction_message) begin
            instruction_message <= spi_shift_reg_in;
        end
    end
    
    always @(posedge SCK) begin
        spi_shift_reg_in <= {spi_shift_reg_in[MESSAGE_BIT_WIDTH-2:0], MOSI};
    end

    always @(negedge SCK, posedge RST_async) begin
        if (RST_async) begin
            spi_shift_reg_out   <= 0;

            load_new_in_message <= 0;
            out_message_ready   <= 0;
        // If the main has sent one complete data message, write the data to the output register
        end else if (write && message_complete && at_least_one_data_message) begin
            spi_shift_reg_out <= 0;
            current_address   <= start_address + transaction_counter - 1;
            out_message       <= spi_shift_reg_in;

            out_message_ready <= 1;
        // If we have just received a new read instruction
        end else if (spi_shift_reg_in[MESSAGE_BIT_WIDTH-1] && received_instruction_message) begin
            spi_shift_reg_out <= new_shift_reg_out;
            current_address   <= spi_shift_reg_in[START_ADDRESS_BIT_WIDTH+NUM_TRANSACTIONS_BIT_WIDTH-1:NUM_TRANSACTIONS_BIT_WIDTH];

            load_new_in_message <= 1;
        // If the main just received a complete data message and we stil have more transactions to do
        end else if (read && message_complete && at_least_one_data_message && (transaction_counter < num_transactions)) begin
            spi_shift_reg_out <= new_shift_reg_out;
            current_address   <= start_address + transaction_counter;

            load_new_in_message <= 1;
        // If we are in the first clockcycle after receiving the complete instruction message and we are reading from client to main
        end else if (read && within_message_counter_zero && at_least_one_data_message) begin
            spi_shift_reg_out <= in_message << 1;

            load_new_in_message <= 0;
            out_message_ready   <= 0;
        end else if (within_message_counter_zero) begin
            out_message_ready   <= 0;
        end else begin
            spi_shift_reg_out <= new_shift_reg_out;
        end
    end

    assign MISO = (read && within_message_counter_zero && at_least_one_data_message) ? in_message[MESSAGE_BIT_WIDTH-1] : spi_shift_reg_out[MESSAGE_BIT_WIDTH-1];

    // We continuously assign these signals for the config memory, as we want the config module to write data to its
    // internal registers on the posedge of the clock. This because, at the point out_message_ready is high, 
    // MESSAGE_BIT_WIDTH clockcycles have passed and so there will never be a positive or negative edge anymore to
    // trigger the config memory to write the data into its internal registers.
    assign config_message_ready = write && (code == 0) && message_complete && at_least_one_data_message;
    assign current_config_address = start_address + transaction_counter - 1;
    assign out_config_message = {spi_shift_reg_in[MESSAGE_BIT_WIDTH-2:0], MOSI};
    
endmodule
