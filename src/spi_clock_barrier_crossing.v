`include "double_latching_barrier.v"

module spi_clock_barrier_crossing
    (
        input clk,
        input rst,

        input enable_configuration,

        input out_message_ready,
        input load_new_in_message,

        output write_new,
        output read_sync
    );

    // Read barrier -------------------------------------------------------------------------------

    double_latching_barrier double_latching_barrier_read (
        .clk(clk), .rst(rst), .enable(enable_configuration),
        .in(load_new_in_message), .out(read_sync)
    );

    // Write barrier ------------------------------------------------------------------------------

    // _sync_intermediate is the first register of the double sampling barrier,
    // _sync is the second (which you can use in the clk clock domain without
    // risking metastability). However, it stays high for more than a cycle in
    // the clk clock domain. I therefore add a third register (_delete) and
    // compare when _sync goes high and _delete is not yet high. _new is thus
    // high only for one clock cycle per SPI transaction, which I use to
    // trigger a write to the SRAM.

    wire write_sync;

    double_latching_barrier double_latching_barrier_write (
        .clk(clk), .rst(rst), .enable(enable_configuration),
        .in(out_message_ready), .out(write_sync)
    );

    reg write_delete;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            write_delete <= 0;
        end else if (enable_configuration) begin
            write_delete <= write_sync;
        end
    end

    assign write_new = write_sync & ~write_delete;

endmodule
