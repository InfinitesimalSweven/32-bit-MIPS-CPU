`include "_timescale.sv"

module tb_eqcmp;
    parameter N = 8;
    logic [N-1:0] a, b;
    logic eq;

    eqcmp #(.n(N)) dut (.a(a), .b(b), .eq(eq));

    task check(input [N-1:0] ta, tb_val, input exp, input [63:0] tnum);
        a = ta; b = tb_val; #1;
        if (eq === exp) $display("PASS TEST %0d: a=%h b=%h eq=%b", tnum, ta, tb_val, eq);
        else            $display("FAIL TEST %0d: a=%h b=%h eq=%b (expected %b)", tnum, ta, tb_val, eq, exp);
    endtask

    initial begin
        $dumpfile("tb_eqcmp.vcd"); $dumpvars(0, tb_eqcmp);

        check(8'hAA, 8'hAA, 1, 1); // equal
        check(8'hAA, 8'hBB, 0, 2); // not equal
        check(8'h00, 8'h00, 1, 3); // zeros
        check(8'hFF, 8'hFF, 1, 4); // all ones
        check(8'hFF, 8'h00, 0, 5); // max vs min

        $display("Done."); $finish;
    end
endmodule