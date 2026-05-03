`ifndef FLOPENR_SV
`define FLOPENR_SV



module flopenr #(parameter n = 32) (
    input  logic             clk,
    input  logic             reset,
    input  logic             en,
    input  logic [(n-1):0] d,
    output logic [(n-1):0] q
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= {n{1'b0}};
        end else if (en) begin
            q <= d;
        end
    end

endmodule



`endif // FLOPENR_SV