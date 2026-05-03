`ifndef TB_CACHE_FULLY_ASSOCIATIVE_SV
`define TB_CACHE_FULLY_ASSOCIATIVE_SV
`include "_timescale.sv"
`include "cache_fully_associative.sv"

module tb_cache_fully_associative;

    logic        clk, reset;
    logic [31:0] cpu_addr, cpu_writedata;
    logic        cpu_memwrite, cpu_memread;
    logic [31:0] cpu_readdata;
    logic        mem_stall;
    logic [31:0] dmem_addr, dmem_writedata;
    logic        dmem_memwrite, dmem_memread;
    logic [31:0] dmem_readdata;
    logic        dmem_ready;

    int pass = 0, fail = 0;

    cache_fully_associative dut (
        .clk(clk), .reset(reset),
        .cpu_addr(cpu_addr), .cpu_writedata(cpu_writedata),
        .cpu_memwrite(cpu_memwrite), .cpu_memread(cpu_memread),
        .cpu_readdata(cpu_readdata), .mem_stall(mem_stall),
        .dmem_addr(dmem_addr), .dmem_writedata(dmem_writedata),
        .dmem_memwrite(dmem_memwrite), .dmem_memread(dmem_memread),
        .dmem_readdata(dmem_readdata), .dmem_ready(dmem_ready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check_hit(input [31:0] expected_data, input string label);
        if (!mem_stall && cpu_readdata === expected_data) begin
            $display("PASS [%s]: readdata=0x%08h no stall", label, cpu_readdata);
            pass++;
        end else begin
            $display("FAIL [%s]: readdata=0x%08h stall=%b (expected data=0x%08h no stall)",
                     label, cpu_readdata, mem_stall, expected_data);
            fail++;
        end
    endtask

    task check_miss(input string label);
        if (mem_stall) begin
            $display("PASS [%s]: correctly stalled on miss", label);
            pass++;
        end else begin
            $display("FAIL [%s]: expected stall on miss but got none", label);
            fail++;
        end
    endtask

    // simulates memory responding after 2 cycles
    task memory_respond(input [31:0] data);
        dmem_ready = 0;
        dmem_readdata = data;
        @(posedge clk); #1;
        @(posedge clk); #1;
        dmem_ready = 1;
        @(posedge clk); #1;
        dmem_ready = 0;
    endtask

    // fills a single address into cache
    task fill_address(input [31:0] addr, input [31:0] data);
        cpu_addr = addr; cpu_memread = 1; cpu_memwrite = 0;
        #1;
        memory_respond(data);
        cpu_memread = 0;
        @(posedge clk); #1;
    endtask

    initial begin
        // reset
        reset = 1; cpu_addr = 0; cpu_writedata = 0;
        cpu_memwrite = 0; cpu_memread = 0;
        dmem_readdata = 0; dmem_ready = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        reset = 0;

        // read miss: cold cache, any address should miss
        cpu_addr = 32'h00000004; cpu_memread = 1; cpu_memwrite = 0;
        #1;
        check_miss("READ MISS cold cache");
        memory_respond(32'hDEADBEEF);
        cpu_memread = 0;
        @(posedge clk); #1;

        // read hit: same address should now be cached
        cpu_addr = 32'h00000004; cpu_memread = 1; cpu_memwrite = 0;
        #1;
        check_hit(32'hDEADBEEF, "READ HIT after fill");
        cpu_memread = 0;
        @(posedge clk); #1;

        // fully associative: two addresses with same lower bits should BOTH be cached (no conflict)
        // unlike direct mapped, 0x00000004 and 0x00000044 can coexist
        cpu_addr = 32'h00000044; cpu_memread = 1; cpu_memwrite = 0;
        #1;
        check_miss("READ MISS different address");
        memory_respond(32'hAABBCCDD);
        cpu_memread = 0;
        @(posedge clk); #1;

        // original address should still be cached (no eviction yet)
        cpu_addr = 32'h00000004; cpu_memread = 1; cpu_memwrite = 0;
        #1;
        check_hit(32'hDEADBEEF, "READ HIT original still cached (no conflict eviction)");
        cpu_memread = 0;
        @(posedge clk); #1;

        // write hit: update cached address
        cpu_addr = 32'h00000004; cpu_writedata = 32'hCAFEBABE;
        cpu_memread = 0; cpu_memwrite = 1;
        @(posedge clk); #1;
        if (dmem_memwrite) begin
            $display("PASS [WRITE HIT write-through]: dmem_memwrite asserted");
            pass++;
        end else begin
            $display("FAIL [WRITE HIT write-through]: expected dmem_memwrite");
            fail++;
        end
        cpu_memwrite = 0;
        @(posedge clk); #1;

        // verify cache updated after write
        cpu_addr = 32'h00000004; cpu_memread = 1;
        #1;
        check_hit(32'hCAFEBABE, "READ HIT after write");
        cpu_memread = 0;
        @(posedge clk); #1;

        // fill all 16 blocks to test FIFO eviction
        // block 0 (0x00000004) and block 1 (0x00000044) already filled
        // fill 14 more unique addresses
        begin
            int i;
            for (i = 2; i < 16; i++) begin
                fill_address(32'h00000100 + i*4, 32'hF0000000 + i);
            end
        end

        // now cache is full — next miss should evict block 0 (FIFO, replace_ptr wraps to 0)
        cpu_addr = 32'hFFFF0000; cpu_memread = 1; cpu_memwrite = 0;
        #1;
        check_miss("READ MISS cache full triggers FIFO eviction");
        memory_respond(32'h11223344);
        cpu_memread = 0;
        @(posedge clk); #1;

        // first filled address (0x00000004) should now be evicted
        cpu_addr = 32'h00000004; cpu_memread = 1; cpu_memwrite = 0;
        #1;
        check_miss("EVICTION: first block evicted after FIFO wraparound");
        cpu_memread = 0;
        dmem_ready = 1; @(posedge clk); #1; dmem_ready = 0;

        $display("\n=== Results: %0d passed, %0d failed ===", pass, fail);
        $finish;
    end

endmodule
`endif // TB_CACHE_FULLY_ASSOCIATIVE_SV