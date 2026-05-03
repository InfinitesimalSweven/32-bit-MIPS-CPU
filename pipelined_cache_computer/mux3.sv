`ifndef MUX3_SV
`define MUX3_SV



module mux3 #(parameter n = 32) (
    input  logic [(n-1):0] d0, d1, d2,
    input  logic [1:0]       s,
    output logic [(n-1):0] y
);

    always_comb begin
        case (s)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            default: y = {n{1'bx}};
        endcase
    end

endmodule



`endif // MUX3_SV