`include "double_flop_synchronizer.v"
`include "triple_flop_toggle_synchronizer.v"

module spi_clock_barrier_crossing (
    input clk,
    input rst,

    input enable_configuration,

    input MOSI_data_ready,
    input load_MISO_data,

    output write_new,
    output read_sync
);

    // Read barrier -------------------------------------------------------------------------------

    double_flop_synchronizer double_flop_synchronizer_read (
        .clk(clk),
        .rst(rst),
        .enable(enable_configuration),
        .in(load_MISO_data),
        .out(read_sync)
    );

    // Write barrier ------------------------------------------------------------------------------

    // Below text considers the wires inside of the
    // _sync_intermediate is the first register of the double sampling barrier,
    // _sync is the second (which you can use in the clk clock domain without
    // risking metastability). However, it stays high for more than a cycle in
    // the clk clock domain. I therefore add a third register (_delete) and
    // compare when _sync goes high and _delete is not yet high. _new is thus
    // high only for one clock cycle per SPI transaction, which I use to
    // trigger a write to the SRAM.

    triple_flop_toggle_synchronizer triple_flop_toggle_synchronizer_write (
        .clk(clk),
        .rst(rst),
        .enable(enable_configuration),
        .in(MOSI_data_ready),
        .out(write_new)
    );

endmodule
