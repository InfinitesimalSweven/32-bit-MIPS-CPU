`ifndef EQCMP_SV
`define EQCMP_SV


module eqcmp
    #(parameter n = 32)(
    input  logic [(n-1):0] a, b,
    output logic           eq
);
    
    assign eq = (a == b);

endmodule



`endif // EQCMP_SV