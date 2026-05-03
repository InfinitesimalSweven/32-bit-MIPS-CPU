`ifndef ALU_SV
`define ALU_SV


module alu
    #(parameter n = 32)(
    //
    // ---------------- PORT DEFINITIONS ----------------
    //
    input  logic        clk,
    input  logic [(n-1):0] a, b,
    input  logic [3:0]  alucontrol,
    output logic [(n-1):0] result,
    output logic        zero
);
    //
    // ---------------- MODULE DESIGN IMPLEMENTATION ----------------
    //
    logic [(n-1):0] condinvb, sumSlt;
    logic [(2*n-1):0] HiLo;

    assign zero = (result == {n{1'b0}}); // zero result control signal
    assign condinvb = alucontrol[2] ? ~b : b;
    assign sumSlt = a + condinvb + alucontrol[2]; // (a-b using 2s complement) test if a == b, if b<a, then sumSlt will have neg bit[31]

    // initialize the internal HiLo register used in multiplying two 32-bit numbers = a 64-bit number.
    initial
        begin
            HiLo = 64'b0;
        end

    always @(*) begin
        case (alucontrol)
            4'b0000: result = a & b;             // and
            4'b0001: result = a | b;             // or
            4'b0010: result = a + b;             // add
            4'b0011: result = ~(a | b);           // nor
            4'b0100: result = HiLo[(n-1):0];     // MFLO
            4'b0101: result = HiLo[(2*n-1):n];   // MFHI
            4'b0110: result = sumSlt; // sub
            // 4'b0111: result = sumSlt[(n-1)];     // slt
            4'b0111: begin                       // slt
                if (a[31] != b[31])
                    if (a[31] > b[31])
                        result = 1;
                    else
                        result = 0;
                else
                    if (a < b)
                        result = 1;
                    else
                        result = 0;
            end
            default: result = {n{1'b0}};
        endcase
    end

    //Multiply and divide results are only stored at clock falling edge.
    always @(negedge clk) begin
        case (alucontrol)
            4'b1000: HiLo = a * b; // mult
            4'b1001: // div
            begin
                HiLo[(n-1):0] = a / b;
                HiLo[(2*n-1):n] = a % b;
            end
        endcase             
    end

endmodule



`endif // ALU_SV