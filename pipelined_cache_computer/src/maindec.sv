`ifndef MAINDEC_SV
`define MAINDEC_SV

module maindec
    #(parameter n = 32)(
    //
    // ---------------- PORT DEFINITIONS ----------------
    //
    input  logic [5:0] op,
    input  logic [5:0] funct,
    output logic       memtoreg, memwrite,
    output logic       branch, alusrc,
    output logic       regdst, regwrite,
    output logic       jump,
    output logic       jal,
    output logic       jr,
    output logic [1:0] aluop
);

    //
    // ---------------- MODULE DESIGN IMPLEMENTATION ----------------
    //
    logic [8:0] controls; // 9-bit control vector

    // controls has 9 logical signals
    assign {regwrite, regdst, alusrc, branch, memwrite,
            memtoreg, jump, aluop} = controls;

    assign jal = (op == 6'b000011);
    assign jr  = (op == 6'b000000) && (funct == 6'b001000);

    always @* begin
        case(op)
            6'b000000: controls <= 9'b110000010; // RTYPE
            6'b100011: controls <= 9'b101001000; // LW
            6'b101011: controls <= 9'b001010000; // SW
            6'b000100: controls <= 9'b000100001; // BEQ
            6'b001000: controls <= 9'b101000000; // ADDI
            6'b000010: controls <= 9'b000000100; // J
            6'b000011: controls <= 9'b100000100; // JAL
            default:   controls <= 9'b000000000; // illegal operation defaults to NOP logic to prevent X cascades
        endcase
    end

endmodule



`endif // MAINDEC_SV