`ifndef MEM_SV
`define MEM_SV



module mem
    #(parameter n = 32, parameter r = 8)(
    input  logic           clk, we,
    input  logic [(n-1):0] addr, wd,
    output logic [(n-1):0] rd
);
    logic [(n-1):0] RAM[0:(2**r-1)];

    initial begin
        string prog_file;
        if ($value$plusargs("PROG=%s", prog_file)) begin
            $readmemh(prog_file, RAM);
        end else begin
            $readmemh("fib_prog.exe", RAM);
        end
    end

    assign rd = RAM[addr[r+1:2]]; // word aligned indexing

    always_ff @(posedge clk) begin
        if (we) RAM[addr[r+1:2]] <= wd;
    end

endmodule



`endif // MEM_SV