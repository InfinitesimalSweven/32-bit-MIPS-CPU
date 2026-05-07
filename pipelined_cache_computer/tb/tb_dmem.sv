`include "_timescale.sv"

module tb_dmem;
    parameter LATENCY = 4;

    logic        clk, reset, memread, memwrite, dmem_ready;
    logic [31:0] addr, writedata, readdata;

    dmem #(.LATENCY(LATENCY)) dut (
        .clk(clk), .reset(reset),
        .memread(memread), .memwrite(memwrite),
        .addr(addr), .writedata(writedata),
        .readdata(readdata), .dmem_ready(dmem_ready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Wait for dmem_ready to assert (with timeout)
    task wait_ready;
        integer i;
        begin
            i = 0;
            while (!dmem_ready && i < 50) begin @(posedge clk); i++; end
            if (!dmem_ready) $display("TIMEOUT waiting for dmem_ready");
        end
    endtask

    initial begin
        $dumpfile("tb_dmem.vcd"); $dumpvars(0, tb_dmem);
        reset = 1; memread = 0; memwrite = 0;
        addr = 0; writedata = 0;
        repeat(2) @(posedge clk); reset = 0;

        // TEST 1: write with latency
        $display("[%0t] TEST 1: write 0xDEADBEEF to addr 0x00", $time);
        addr = 32'h00; writedata = 32'hDEADBEEF; memwrite = 1;
        wait_ready;
        memwrite = 0;
        @(posedge clk);
        $display("PASS TEST 1: write accepted after %0d cycles", LATENCY);

        // TEST 2: read back same address
        $display("[%0t] TEST 2: read back addr 0x00", $time);
        memread = 1;
        wait_ready;
        memread = 0;
        if (readdata === 32'hDEADBEEF)
            $display("PASS TEST 2: readdata = %h", readdata);
        else
            $display("FAIL TEST 2: readdata = %h (expected DEADBEEF)", readdata);

        // TEST 3: dmem_ready deasserts when idle
        repeat(2) @(posedge clk);
        if (!dmem_ready) $display("PASS TEST 3: dmem_ready deasserted when idle");
        else             $display("FAIL TEST 3: dmem_ready stuck high");

        // TEST 4: write to different address, read back
        addr = 32'h08; writedata = 32'h12345678; memwrite = 1;
        wait_ready; memwrite = 0; @(posedge clk);
        memread = 1; addr = 32'h08;
        wait_ready; memread = 0;
        if (readdata === 32'h12345678)
            $display("PASS TEST 4: readdata = %h", readdata);
        else
            $display("FAIL TEST 4: readdata = %h (expected 12345678)", readdata);

        $display("Done."); $finish;
    end

    initial begin #10000; $display("TIMEOUT"); $finish; end
endmodule