`ifndef FLOPENRC_SV
`define FLOPENRC_SV

module flopenrc
    #(parameter n = 32)(
    input  logic             clk, reset,
    input  logic             en, clear,
    input  logic [(n-1):0]   d,
    output logic [(n-1):0]   q
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 0;
        end else if (en) begin
            if (clear) q <= 0;
            else       q <= d;
        end
    end

endmodule



`endif // FLOPENRC_SV