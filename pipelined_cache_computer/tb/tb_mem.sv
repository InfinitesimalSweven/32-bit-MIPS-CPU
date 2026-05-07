`include "_timescale.sv"

module tb_mem;
    logic        clk, we;
    logic [31:0] addr, wd, rd;

    mem #(.n(32), .r(6)) dut (.clk(clk), .we(we), .addr(addr), .wd(wd), .rd(rd));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_mem.vcd"); $dumpvars(0, tb_mem);
        we = 0; addr = 0; wd = 0;
        @(posedge clk); #1;

        // TEST 1: write then read back (word-aligned addr)
        addr = 32'h00000000; wd = 32'hDEADBEEF; we = 1;
        @(posedge clk); #1; we = 0;
        if (rd === 32'hDEADBEEF) $display("PASS TEST 1: write/read addr=0x00 data=%h", rd);
        else                     $display("FAIL TEST 1: rd=%h", rd);

        // TEST 2: write to different word address (byte addr 0x08 -> word index 2)
        addr = 32'h00000008; wd = 32'h12345678; we = 1;
        @(posedge clk); #1; we = 0;
        if (rd === 32'h12345678) $display("PASS TEST 2: write/read addr=0x08 data=%h", rd);
        else                     $display("FAIL TEST 2: rd=%h", rd);

        // TEST 3: we=0 does not overwrite
        addr = 32'h00000008; wd = 32'hFFFFFFFF; we = 0;
        @(posedge clk); #1;
        if (rd === 32'h12345678) $display("PASS TEST 3: we=0 preserves data");
        else                     $display("FAIL TEST 3: rd=%h (was overwritten)", rd);

        // TEST 4: first address unaffected by second write
        addr = 32'h00000000; #1;
        if (rd === 32'hDEADBEEF) $display("PASS TEST 4: addr=0 unaffected by other writes");
        else                     $display("FAIL TEST 4: rd=%h", rd);

        $display("Done."); $finish;
    end
endmodule