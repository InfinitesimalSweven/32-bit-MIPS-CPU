`ifndef DFF_SV
`define DFF_SV

module dff
    #(parameter n = 32)(
    //M 
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