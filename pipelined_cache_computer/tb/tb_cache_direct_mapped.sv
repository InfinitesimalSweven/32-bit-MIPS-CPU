`ifndef TB_CACHE_DIRECT_MAPPED_SV
`define TB_CACHE_DIRECT_MAPPED_SV
`include "_timescale.sv"
`include "cache_direct_mapped.sv"

module tb_cache_direct_mapped;

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

    cache_direct_mapped dut (
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

    initial begin
        // reset
        reset = 1; cpu_addr = 0; cpu_writedata = 0;
        cpu_memwrite = 0; cpu_memread = 0;
        dmem_readdata = 0; dmem_ready = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        reset = 0;

        // read miss: address 0x00000004, index=1, tag=0
        // cache is empty so should stall and go fetch from memory
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

        // write hit: write to same address, should update cache and write through
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

        // read hit after write: verify cache was updated
        cpu_addr = 32'h00000004; cpu_memread = 1;
        #1;
        check_hit(32'hCAFEBABE, "READ HIT after write");
        cpu_memread = 0;
        @(posedge clk); #1;

        // write miss: new address that hasn't been cached
        cpu_addr = 32'h00000008; cpu_writedata = 32'h12345678;
        cpu_memread = 0; cpu_memwrite = 1;
        #1;
        check_miss("WRITE MISS new address");
        memory_respond(32'h00000000);
        cpu_memwrite = 0;
        @(posedge clk); #1;

        // conflict miss: two addresses that map to same index (same index bits [5:2], different tag bits [31:6])
        // 0x00000004 and 0x00000044 both have index=1 but different tags
        cpu_addr = 32'h00000044; cpu_memread = 1; cpu_memwrite = 0;
        #1;
        check_miss("CONFLICT MISS same index different tag");
        memory_respond(32'hAABBCCDD);
        cpu_memread = 0;
        @(posedge clk); #1;

        // original address 0x00000004 should now be evicted
        cpu_addr = 32'h00000004; cpu_memread = 1;
        #1;
        check_miss("EVICTION: original address evicted after conflict");
        cpu_memread = 0;
        dmem_ready = 1; @(posedge clk); #1; dmem_ready = 0;

        $display("\n=== Results: %0d passed, %0d failed ===", pass, fail);
        $finish;
    end

endmodule
`endif // TB_CACHE_DIRECT_MAPPED_SV