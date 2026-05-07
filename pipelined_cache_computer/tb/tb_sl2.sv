`include "_timescale.sv"

module tb_sl2;
    logic [31:0] a, y;

    sl2 #(.n(32)) dut (.A(a), .Y(y));

    task check(input [31:0] in, exp, input integer tnum);
        a = in; #1;
        if (y === exp) $display("PASS TEST %0d: A=%h Y=%h", tnum, in, y);
        else           $display("FAIL TEST %0d: Y=%h (expected %h)", tnum, y, exp);
    endtask

    initial begin
        $dumpfile("tb_sl2.vcd"); $dumpvars(0, tb_sl2);
        check(32'h00000001, 32'h00000004, 1); // 1 << 2 = 4
        check(32'h00000005, 32'h00000014, 2); // 5 << 2 = 20
        check(32'hFFFFFFFF, 32'hFFFFFFFC, 3); // all ones shifts, lower 2 become 00
        check(32'h00000000, 32'h00000000, 4); // zero stays zero
        check(32'h40000000, 32'h00000000, 5); // MSBs shift out
        $display("Done."); $finish;
    end
endmodule