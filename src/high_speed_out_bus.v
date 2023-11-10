module high_speed_out_bus
    #(parameter HIGH_SPEED_OUT_PINS = 8, parameter SENT_COUNTER_BIT_WIDTH=4)
    (
        input clk,
        input rst,

        input in_idle,
        input sending,
        input will_stop_sending, // next_state != `SENDING
        
        input [SENT_COUNTER_BIT_WIDTH-1:0] num_sends,

        input [HIGH_SPEED_OUT_PINS-1:0] in,

        output reg request,
        input acknowledge,

        output reg [HIGH_SPEED_OUT_PINS-1:0] out,
        output reg [SENT_COUNTER_BIT_WIDTH-1:0] sent_counter,

        output done_sending
    );

    wire acknowledge_sync;
    double_latching_barrier double_latching_barrier_acknowledge (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .in(acknowledge),
        .out(acknowledge_sync)
    );

    assign done_sending = acknowledge_sync & !request & (sent_counter == num_sends);

    always @(posedge clk) begin
        // TODO: is a reset every idle cycle really necessary?
        if (in_idle) begin
            request <= 1'b0;
            out <= 0;
            sent_counter <= 0;
        end else if (sending && will_stop_sending) begin
            request <= 1'b0;
            sent_counter <= 0;
        end else if (sending && (sent_counter <= num_sends)) begin
            if (!acknowledge_sync && !request) begin
                request <= 1'b1;
                out <= in;
            end else if (acknowledge_sync && request) begin
                request <= 1'b0;
                sent_counter <= sent_counter + 1;
            end
        end
    end
endmodule