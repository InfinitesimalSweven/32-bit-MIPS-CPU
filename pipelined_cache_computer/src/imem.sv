`ifndef IMEM_SV
`define IMEM_SV


module imem
// n=bit length of register; r=bit length of addr to limit memory and not crash your verilog emulator
    #(parameter n = 32, parameter r = 8)(
    //
    // ---------------- PORT DEFINITIONS ----------------
    //
    input  logic [(r-1):0] addr,
    output logic [(n-1):0] readdata
);
    //
    // ---------------- MODULE DESIGN IMPLEMENTATION ----------------
    //
    logic [(n-1):0] RAM[0:(2**r-1)];

  initial
    begin
      string prog_file;
      if ($value$plusargs("PROG=%s", prog_file)) begin
          $readmemh(prog_file, RAM);
      end else begin
          $readmemh("test_prog.exe", RAM);
      end
    end

  assign readdata = RAM[addr]; // word aligned

endmodule



`endif // IMEM_SV