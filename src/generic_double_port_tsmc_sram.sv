`ifndef __GENERIC_DOUBLE_PORT_TSMC_SRAM_SV__
`define __GENERIC_DOUBLE_PORT_TSMC_SRAM_SV__

// Implementation based of off:
// https://github.com/ChFrenkel/ReckOn/blob/5e5c0bea8fe1897876ba3b7bfdcecf76d3bf4505/src/srnn.v#L1407

module generic_double_port_tsmc_sram
    #(parameter WIDTH = 128, parameter NUM_ROWS = 4096, localparam ADDRESS_WIDTH = $clog2(NUM_ROWS))
    (
        // Global inputs
        input CLK, // Clock (synchronous read/write)

        // Control and data inputs
        input REB, // Read enable (active high)
        input WEB, // Write enable (active high)
        input [ADDRESS_WIDTH-1:0] AA, // Address bus (write)
        input [ADDRESS_WIDTH-1:0] AB, // Address bus (read)
        input [WIDTH-1:0] D, // Data input bus (write)
        input [WIDTH-1:0] M, // Mask bus (write, 1=overwrite)

        // Data output
        output [WIDTH-1:0] Q // Data output bus (read)   
    );
   
    reg [WIDTH-1:0] SRAM [NUM_ROWS-1:0];
    reg [WIDTH-1:0] Qr;

    always @(posedge CLK) begin
        Qr <= REB ? SRAM[AB] : Qr;
        
        if (WEB) begin
            SRAM[AA] <= (D & M) | (SRAM[AA] & ~M);
        end
    end

    assign Q = Qr;
    
endmodule

`endif
