`include "_timescale.sv"

module tb_mux4;
    parameter N = 8;
    logic [N-1:0] d0, d1, d2, d3, y;
    logic [1:0] s;

    mux4 #(.n(N)) dut (.d0(d0), .d1(d1), .d2(d2), .d3(d3), .s(s), .y(y));

    task check(input [1:0] sel, input [N-1:0] exp, input integer tnum);
        s = sel; #1;
        if (y === exp) $display("PASS TEST %0d: s=%b y=%h", tnum, sel, y);
        else           $display("FAIL TEST %0d: y=%h (expected %h)", tnum, y, exp);
    endtask

    initial begin
        $dumpfile("tb_mux4.vcd"); $dumpvars(0, tb_mux4);
        d0 = 8'hAA; d1 = 8'hBB; d2 = 8'hCC; d3 = 8'hDD;
        check(2'b00, 8'hAA, 1);
        check(2'b01, 8'hBB, 2);
        check(2'b10, 8'hCC, 3);
        check(2'b11, 8'hDD, 4);
        $display("Done."); $finish;
    end
endmodule