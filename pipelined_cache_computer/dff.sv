`ifndef DFF_SV
`define DFF_SV

//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2023
// Engineer: Prof Rob Marano
// 
//     Create Date: 2023-02-07
//     Module Name: dff
//     Description: 32 bit D flip flop
//
// Revision: 1.0
//
//////////////////////////////////////////////////////////////////////////////////


module dff
    #(parameter n = 32)(
    //
    // ---------------- PORT DEFINITIONS ----------------
    //
    input  logic CLOCK, RESET,
    input  logic [(n-1):0] D,
    output logic [(n-1):0] Q
);
    //
    // ---------------- MODULE DESIGN IMPLEMENTATION ----------------
    //
    always @(posedge CLOCK, posedge RESET)
    begin
        if (RESET)
        begin
            Q <= 0;
        end
        else
        begin
            Q <= D;
        end
    end
endmodule



`endif // DFF_SV