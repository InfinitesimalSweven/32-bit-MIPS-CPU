`include "_timescale.sv"

module tb_mux2;
    parameter N = 8;
    logic [N-1:0] d0, d1, y;
    logic s;

    mux2 #(.n(N)) dut (.D0(d0), .D1(d1), .S(s), .Y(y));

    task check(input [N-1:0] a, b, input sel, exp, input integer tnum);
        d0 = a; d1 = b; s = sel; #1;
        if (y === exp) $display("PASS TEST %0d: s=%b y=%h", tnum, sel, y);
        else           $display("FAIL TEST %0d: y=%h (expected %h)", tnum, y, exp);
    endtask

    initial begin
        $dumpfile("tb_mux2.vcd"); $dumpvars(0, tb_mux2);
        check(8'hAA, 8'hBB, 0, 8'hAA, 1); // S=0 -> D0
        check(8'hAA, 8'hBB, 1, 8'hBB, 2); // S=1 -> D1
        check(8'h00, 8'hFF, 0, 8'h00, 3); // zero
        check(8'h00, 8'hFF, 1, 8'hFF, 4); // all ones
        $display("Done."); $finish;
    end
endmodule