`include "_timescale.sv"

module tb_flopenrc;
    parameter N = 8;
    logic clk, reset, en, clear;
    logic [N-1:0] d, q;

    flopenrc #(.n(N)) dut (.clk(clk), .reset(reset), .en(en), .clear(clear), .d(d), .q(q));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_flopenrc.vcd"); $dumpvars(0, tb_flopenrc);
        reset = 1; en = 0; clear = 0; d = 0;
        @(posedge clk); #1;

        // TEST 1: async reset
        if (q === 8'h00) $display("PASS TEST 1: reset clears q");
        else             $display("FAIL TEST 1: q=%h", q);
        reset = 0;

        // TEST 2: en=0 blocks capture
        d = 8'hAB; en = 0; @(posedge clk); #1;
        if (q === 8'h00) $display("PASS TEST 2: en=0 blocks capture");
        else             $display("FAIL TEST 2: q=%h", q);

        // TEST 3: en=1, clear=0 captures D
        en = 1; clear = 0; @(posedge clk); #1;
        if (q === 8'hAB) $display("PASS TEST 3: en=1 clear=0 captures d");
        else             $display("FAIL TEST 3: q=%h", q);

        // TEST 4: en=1, clear=1 zeroes Q (sync clear takes priority over D)
        d = 8'hFF; clear = 1; @(posedge clk); #1;
        if (q === 8'h00) $display("PASS TEST 4: en=1 clear=1 zeroes q");
        else             $display("FAIL TEST 4: q=%h", q);

        // TEST 5: clear=0 resumes normal capture after clear
        d = 8'h5A; clear = 0; @(posedge clk); #1;
        if (q === 8'h5A) $display("PASS TEST 5: normal capture resumes after clear");
        else             $display("FAIL TEST 5: q=%h", q);

        // TEST 6: en=0, clear=1 — neither should change Q
        d = 8'hFF; en = 0; clear = 1; @(posedge clk); #1;
        if (q === 8'h5A) $display("PASS TEST 6: en=0 blocks clear");
        else             $display("FAIL TEST 6: q=%h", q);

        $display("Done."); $finish;
    end
endmodule