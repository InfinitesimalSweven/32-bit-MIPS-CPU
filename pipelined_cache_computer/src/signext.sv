`ifndef SIGNEXT_SV
`define SIGNEXT_SV

module signext
    #(parameter n = 32, i = 16)(
    //
    // ---------------- PORT DEFINITIONS ----------------
    //
    input  logic [(i-1):0] A,
    output logic [(n-1):0] Y
);
    //
    // ---------------- MODULE DESIGN IMPLEMENTATION ----------------
    //
    assign Y = { {n{A[(i-1)]}}, A}; // sign extend (i-1)th bit i bits to the left.
endmodule



`endif // SIGNEXT_SV