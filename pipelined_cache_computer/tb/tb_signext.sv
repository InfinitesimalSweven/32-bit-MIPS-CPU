`include "_timescale.sv"

module tb_signext;
    logic [15:0] a;
    logic [31:0] y;

    signext #(.n(32), .i(16)) dut (.A(a), .Y(y));

    task check(input [15:0] in, input [31:0] exp, input integer tnum);
        a = in; #1;
        if (y === exp) $display("PASS TEST %0d: A=%h Y=%h", tnum, in, y);
        else           $display("FAIL TEST %0d: Y=%h (expected %h)", tnum, y, exp);
    endtask

    initial begin
        $dumpfile("tb_signext.vcd"); $dumpvars(0, tb_signext);
        check(16'h0001, 32'h00000001, 1); // positive small
        check(16'h7FFF, 32'h00007FFF, 2); // max positive
        check(16'h8000, 32'hFFFF8000, 3); // min negative (MSB=1)
        check(16'hFFFF, 32'hFFFFFFFF, 4); // all ones
        check(16'h0000, 32'h00000000, 5); // zero
        $display("Done."); $finish;
    end
endmodule