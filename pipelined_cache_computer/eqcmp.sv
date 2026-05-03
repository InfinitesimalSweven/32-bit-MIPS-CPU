`ifndef EQCMP_SV
`define EQCMP_SV

//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2026
// Engineer: Prof Rob Marano
// 
//     Create Date: 2026-04-09
//     Module Name: eqcmp
//     Description: 32-bit Equality Comparator for Branch evaluation
//////////////////////////////////////////////////////////////////////////////////


module eqcmp
    #(parameter n = 32)(
    input  logic [(n-1):0] a, b,
    output logic           eq
);
    
    assign eq = (a == b);

endmodule



`endif // EQCMP_SV