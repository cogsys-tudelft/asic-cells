`ifndef __SINGLE_PORT_TYPE_T_SRAM_SV__
`define __SINGLE_PORT_TYPE_T_SRAM_SV__

/**
 * Implementation based of off:
 * https://github.com/ChFrenkel/ReckOn/blob/5e5c0bea8fe1897876ba3b7bfdcecf76d3bf4505/src/srnn.v#L1407
 *
 * Ports are named in accordance with the type T 40nm SRAM library.
 */
module single_port_type_t_sram #(
    parameter integer WIDTH = 128,
    parameter integer NUM_ROWS = 4096,
    localparam integer AddressWidth = $clog2(NUM_ROWS)
) (
    // Global inputs
    input CLK,  // Clock (synchronous read/write)

    // Control and data inputs
    input CEB,  // "Chip enable, active low for SRAM operation; active high for fuse data setting"
    input WEB,  // Write enable: WEB is low for writing; for reading, WEB is high
    input [AddressWidth-1:0] A,  // Address bus
    input [WIDTH-1:0] D,  // Data input bus (write)
    input [WIDTH-1:0] M,  // Mask bus (overwite = 0, otherwise = 1)

    // Data output
    output [WIDTH-1:0] Q  // Data output bus (read)
);
    reg [WIDTH-1:0] SRAM[NUM_ROWS];
    reg [WIDTH-1:0] Qr;

    always_ff @(posedge CLK) begin
        Qr <= ~CEB ? SRAM[A] : Qr;

        if (~CEB & ~WEB) begin
            SRAM[A] <= (D & ~M) | (SRAM[A] & M);
        end
    end

    assign Q = Qr;

endmodule

`endif
