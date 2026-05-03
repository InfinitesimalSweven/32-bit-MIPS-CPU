`ifndef TB_COMPUTER_SV
`define TB_COMPUTER_SV

`include "_timescale.sv"
//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2026
// Engineer: Prof Rob Marano
// 
//     Create Date: 2026-04-09
//     Module Name: tb_computer
//     Description: Testbench for the Pipelined MIPS CPU
//////////////////////////////////////////////////////////////////////////////////


`include "computer.sv"

module tb_computer;

    logic        clk;
    logic        reset;
    logic        intr;
    logic        cache_en;
    logic [31:0] writedata, dataadr;
    logic        memwrite;
    
    // Instantiate device under test
    computer dut(clk, reset, intr, cache_en, writedata, dataadr, memwrite);

    // clock signal generation
    initial begin
        $dumpfile("tb_computer.vcd");
        $dumpvars(0, tb_computer);
        clk = 0;
        intr = 0;
    end

    always begin
        #5 clk = ~clk;
    end

    // Cycle-by-cycle logging for educational trace routing
    integer cycle = 0;
    integer instr_count = 0;
    integer cache_hits = 0;
    integer cache_misses = 0;

    // ANSI Color Codes
    string C_RST  = "\033[0m";
    string C_RED  = "\033[1;31m";
    string C_YEL  = "\033[1;33m";
    string C_GRN  = "\033[1;32m";
    string C_CYN  = "\033[1;36m";
    string C_PUR  = "\033[1;35m";
    string C_BLU  = "\033[1;34m";
    string C_GRY  = "\033[1;30m";

    always @(posedge clk) begin
        // String builders for visual indicators
        string stallF_str, stallD_str, flushD_str, flushE_str, memwrite_str, regwrite_str;

        if (!reset) begin
            cycle++;
            
            if (dut.mips_pipelined.dp.instrD != 32'b0 && !dut.mips_pipelined.stallD) begin
                instr_count++;
            end

            // Track Hits and Misses in the Cache module
            if ((dut.dcache.cpu_memread || dut.dcache.cpu_memwrite) && dut.dcache.state == 0) begin
                if (dut.dcache.hit) cache_hits++;
                if (dut.dcache.miss) cache_misses++;
            end

            
            if (dut.mips_pipelined.stallD) stallF_str = {C_YEL, ">> STALLED <<", C_RST}; else stallF_str = "      -      ";
            if (dut.mips_pipelined.stallD) stallD_str = {C_YEL, ">> STALLED <<", C_RST}; else stallD_str = "      -      ";
            if (dut.mips_pipelined.flushD) flushD_str = {C_RED, ">> FLUSHED <<", C_RST}; else flushD_str = "      -      ";
            if (dut.mips_pipelined.flushE) flushE_str = {C_RED, ">> FLUSHED <<", C_RST}; else flushE_str = "      -      ";
            if (memwrite) memwrite_str = {C_GRN, "WRITE", C_RST}; else memwrite_str = "  -  ";
            if (dut.mips_pipelined.dp.regwriteW) regwrite_str = {C_GRN, "WRITE", C_RST}; else regwrite_str = "  -  ";

            $display("%s=================================================================================================%s", C_GRY, C_RST);
            $display(" %sCycle %0d%s (Time: %0t)", C_CYN, cycle, C_RST, $time);
            $display("%s-------------------------------------------------------------------------------------------------%s", C_GRY, C_RST);
            $display("  %s[IF]%s   PC: 0x%08h | Status: %s", C_BLU, C_RST, dut.mips_pipelined.dp.pcF, stallF_str);
            $display("  %s[ID]%s   Instr: 0x%08h | rs: %2d, rt: %2d | Stall: %s | Flush: %s", C_PUR, C_RST, dut.mips_pipelined.dp.instrD, dut.mips_pipelined.dp.rsD, dut.mips_pipelined.dp.rtD, stallD_str, flushD_str);
            $display("  %s[EX]%s   ALUOut: 0x%08h | Flush: %s | EPC: 0x%08h", C_YEL, C_RST, dut.mips_pipelined.dp.aluoutE, flushE_str, dut.mips_pipelined.dp.EPC);
            $display("  %s[MEM]%s  MemWrite: %s | Addr: 0x%08h | WriteData: 0x%08h", C_GRN, C_RST, memwrite_str, dataadr, writedata);
            $display("  %s[WB]%s   RegWrite: %s | RegDst: %2d | ResultW: 0x%08h", C_CYN, C_RST, regwrite_str, dut.mips_pipelined.dp.writeregW, dut.mips_pipelined.dp.resultW);
        end
    end

    // initial stimulus
    initial begin
        if ($test$plusargs("CACHE_EN=1")) begin
            cache_en = 1;
            $display("Starting Simulation: CACHE ENABLED");
        end else begin
            cache_en = 0;
            $display("Starting Simulation: CACHE DISABLED (DIRECT TO MAIN MEMORY)");
        end

        reset = 1; #22;
        reset = 0;
    end

    initial begin
        #100000; // Increased timeout for slow dmem loops
        $display("Testbench timeout");
        $finish;
    end

    // check results and print performance metrics on halt
    always @(negedge clk) begin
        if (memwrite) begin
            if (dataadr === 84 && writedata === 12) begin
                $display("\n%sSuccess: mem[84] evaluates to 12. Arithmetic RAW Forwarding logic mapped correctly.%s", C_GRN, C_RST);
            end else if (dataadr === 88 && writedata === 24) begin
                $display("\n%sExtravagant Success: mem[88] evaluates to 24. Pipelined Branch Flushes and Load-Use Stalls executed perfectly!%s", C_GRN, C_RST);
                $display("\n╭─────────────────────────────────────────────────────────────────────────────────────────────────╮");
                $display("│ %-95s │", "Program successfully completed all verification steps.");
                $display("├─────────────────────────────────────────────────────────────────────────────────────────────────┤");
                $display("│ PERFORMANCE METRICS:                                                                            │");
                $display("│ %-95s │", $sformatf("Total Clock Cycles: %0d", cycle));
                $display("│ %-95s │", $sformatf("Instructions Executed: ~%0d", instr_count));
                $display("│ %-95s │", $sformatf("Effective CPI: %0.2f", real'(cycle) / real'(instr_count)));
                $display("│ %-95s │", $sformatf("Cache Hits: %0d", cache_hits));
                $display("│ %-95s │", $sformatf("Cache Misses: %0d", cache_misses));
                $display("╰─────────────────────────────────────────────────────────────────────────────────────────────────╯\n");
                $finish;
            end
            
            // Universal Memory-Mapped I/O Halt
            if (dataadr === 252) begin
                $display("\n╭─────────────────────────────────────────────────────────────────────────────────────────────────╮");
                $display("│ %-95s │", "Program gracefully halted via Memory-Mapped I/O.");
                $display("├─────────────────────────────────────────────────────────────────────────────────────────────────┤");
                $display("│ PERFORMANCE METRICS:                                                                            │");
                $display("│ %-95s │", $sformatf("Total Clock Cycles: %0d", cycle));
                $display("│ %-95s │", $sformatf("Instructions Executed: ~%0d", instr_count));
                $display("│ %-95s │", $sformatf("Effective CPI: %0.2f", real'(cycle) / real'(instr_count)));
                $display("│ %-95s │", $sformatf("Cache Hits: %0d", cache_hits));
                $display("│ %-95s │", $sformatf("Cache Misses: %0d", cache_misses));
                $display("╰─────────────────────────────────────────────────────────────────────────────────────────────────╯\n");
                $finish;
            end
        end
    end

endmodule


`endif // TB_COMPUTER_SV