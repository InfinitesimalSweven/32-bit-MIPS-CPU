`include "_timescale.sv"

module tb_flopenr;
    parameter N = 8;
    logic clk, reset, en;
    logic [N-1:0] d, q;

    flopenr #(.n(N)) dut (.clk(clk), .reset(reset), .en(en), .d(d), .q(q));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_flopenr.vcd"); $dumpvars(0, tb_flopenr);
        reset = 1; en = 0; d = 0;
        @(posedge clk); #1;

        // TEST 1: reset clears Q
        if (q === 8'h00) $display("PASS TEST 1: reset clears q");
        else             $display("FAIL TEST 1: q=%h", q);
        reset = 0;

        // TEST 2: en=0 blocks capture
        d = 8'hAB; en = 0; @(posedge clk); #1;
        if (q === 8'h00) $display("PASS TEST 2: en=0 blocks capture");
        else             $display("FAIL TEST 2: q=%h (expected 00)", q);

        // TEST 3: en=1 captures D
        en = 1; @(posedge clk); #1;
        if (q === 8'hAB) $display("PASS TEST 3: en=1 captures d=0xAB");
        else             $display("FAIL TEST 3: q=%h", q);

        // TEST 4: en=0 holds Q after capture
        d = 8'hFF; en = 0; @(posedge clk); #1;
        if (q === 8'hAB) $display("PASS TEST 4: en=0 holds q");
        else             $display("FAIL TEST 4: q=%h", q);

        // TEST 5: async reset overrides en
        en = 1; d = 8'h55; reset = 1; @(posedge clk); #1;
        if (q === 8'h00) $display("PASS TEST 5: async reset overrides en");
        else             $display("FAIL TEST 5: q=%h", q);

        $display("Done."); $finish;
    end
endmodule