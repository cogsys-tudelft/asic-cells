module high_speed_in_bus (
    input clk,
    input rst,

    input  data_required,
    output data_available, // If data_available is high and rst is low, then you can read the data from the in_data bus.

    input request,
    output reg acknowledge
);
    wire request_sync;

    double_flop_synchronizer double_flop_synchronizer_request (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .in(request),
        .out(request_sync)
    );

    assign data_available = ~acknowledge & request_sync & data_required;

    // Acknowledge logic. We assume that when acknowledge is high, the data is read from the in_data bus by another component
    // in the same clock cycle. Therefore, we can set acknowledge to low in the next clock cycle.
    always @(posedge clk, posedge rst) begin
        if (rst) acknowledge <= 1'b0;
        else if (data_available) acknowledge <= 1'b1;
        else if (acknowledge && !request_sync) acknowledge <= 1'b0;
    end

endmodule
