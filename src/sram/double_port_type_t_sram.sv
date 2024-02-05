`ifndef __DOUBLE_PORT_TYPE_T_SRAM_SV__
`define __DOUBLE_PORT_TYPE_T_SRAM_SV__

/**
 * Implementation based of off:
 * https://github.com/ChFrenkel/ReckOn/blob/5e5c0bea8fe1897876ba3b7bfdcecf76d3bf4505/src/srnn.v#L1407
 *
 * Ports are named in accordance with the type T 40nm SRAM library.
 *
 * This SRAM is double ported, meaning that it can read and write one value at the same.
 * It is however not possible to write two values or read two values at the same time.
 */
module double_port_type_t_sram #(
    parameter integer WIDTH = 128,
    parameter integer NUM_ROWS = 4096,
    localparam integer AddressWidth = $clog2(NUM_ROWS)
) (
    // Global inputs
    input CLK,  // Clock (synchronous read/write)

    // Control and data inputs
    input REB,  // "Chip enable, active low for SRAM operation; active high for fuse data setting"
    input WEB,  // Write enable: WEB is low for writing; for reading, WEB is high
    input [AddressWidth-1:0] AA,  // Address bus (write)
    input [AddressWidth-1:0] AB,  // Address bus (read)
    input [WIDTH-1:0] D,  // Data input bus (write)
    input [WIDTH-1:0] M,  // Mask bus (overwrite = 0, otherwise = 1)

    // Data output
    output [WIDTH-1:0] Q  // Data output bus (read)
);
    reg [WIDTH-1:0] SRAM[NUM_ROWS];
    reg [WIDTH-1:0] Qr;

    always @(posedge CLK) begin
        Qr <= ~REB ? SRAM[AB] : Qr;

        if (~WEB) begin
            SRAM[AA] <= (D & ~M) | (SRAM[AA] & M);
        end
    end

    assign Q = Qr;

endmodule

`endif
