`ifndef REGFILE_SV
`define REGFILE_SV

//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2026
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: regfile
//     Description: 32-bit RISC register file (MIPS)
//
// Revision: 1.0
//
//////////////////////////////////////////////////////////////////////////////////


module regfile(
    input  logic        clk, 
    input  logic        we3, 
    input  logic [4:0]  ra1, ra2, wa3, 
    input  logic [31:0] wd3, 
    output logic [31:0] rd1, rd2
);

    logic [31:0] rf[31:0];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) rf[i] = 0;
    end

    // three ported register file
    // read two ports combinationally
    // write third port on positive edge of clock
    // register 0 hardwired to 0
    always_ff @(negedge clk) begin
        if (we3) rf[wa3] <= wd3;
    end

    assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
    assign rd2 = (ra2 != 0) ? rf[ra2] : 0;

endmodule



`endif // REGFILE_SV