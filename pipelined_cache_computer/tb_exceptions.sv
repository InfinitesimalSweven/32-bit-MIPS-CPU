`ifndef TB_EXCEPTIONS_SV
`define TB_EXCEPTIONS_SV

`timescale 1ns/1ps

`include "computer.sv"

module tb_exceptions();
    logic clk;
    logic reset;
    logic intr;
    logic [31:0] writedata, dataadr;
    logic memwrite;

    computer dut (
        .clk(clk),
        .reset(reset),
        .intr(intr),
        .writedata(writedata),
        .dataadr(dataadr),
        .memwrite(memwrite)
    );

    initial begin
        $dumpfile("tb_exceptions.vcd");
        $dumpvars(0, tb_exceptions);
        
        reset = 1;
        intr = 0;
        clk = 0;
        
        #10 reset = 0;
        
        #95;
        
        // Assert Interrupt right in the middle of executing loop payload
        $display("[%0t] Asserting Interrupt asynchronously!", $time);
        intr = 1;
        #10;
        intr = 0;
        
        // Wait for OS handler to run and modify $k0 (reg 26)
        #200;
        
        $display("\n--- EXCEPTION REPORT ---");
        if (dut.mips_pipelined.dp.rf.rf[26] === 32'd999) begin
            $display("SUCCESS: OS Exception Handler executed gracefully! $k0 == 999");
        end else begin
            $display("FAIL: Exception Handler did not set $k0! Found: %d", dut.mips_pipelined.dp.rf.rf[26]);
        end
        
        $display("EPC captured PC sequence: 0x%08h", dut.mips_pipelined.dp.EPC);
        $finish;
    end

    // Cycle-by-cycle logging for educational trace routing
    integer cycle = 0;

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
        string stallF_str, stallD_str, flushD_str, flushE_str, memwrite_str, regwrite_str, intr_str;

        if (!reset) begin
            cycle++;
            
            if (dut.mips_pipelined.stallF) stallF_str = {C_YEL, ">> STALLED <<", C_RST}; else stallF_str = "      -      ";
            if (dut.mips_pipelined.stallD) stallD_str = {C_YEL, ">> STALLED <<", C_RST}; else stallD_str = "      -      ";
            if (dut.mips_pipelined.flushD) flushD_str = {C_RED, ">> FLUSHED <<", C_RST}; else flushD_str = "      -      ";
            if (dut.mips_pipelined.flushE) flushE_str = {C_RED, ">> FLUSHED <<", C_RST}; else flushE_str = "      -      ";
            if (memwrite) memwrite_str = {C_GRN, "WRITE", C_RST}; else memwrite_str = "  -  ";
            if (dut.mips_pipelined.dp.regwriteW) regwrite_str = {C_GRN, "WRITE", C_RST}; else regwrite_str = "  -  ";
            if (intr) intr_str = {C_RED, "!!! INTERRUPT PIN HIGH !!!", C_RST}; else intr_str = "Normal";

            $display("%s=================================================================================================%s", C_GRY, C_RST);
            $display(" %sCycle %0d%s (Time: %0t) [%s]", C_CYN, cycle, C_RST, $time, intr_str);
            $display("%s-------------------------------------------------------------------------------------------------%s", C_GRY, C_RST);
            $display("  %s[IF]%s   PC: 0x%08h | Status: %s", C_BLU, C_RST, dut.mips_pipelined.dp.pcF, stallF_str);
            $display("  %s[ID]%s   Instr: 0x%08h | rs: %2d, rt: %2d | Stall: %s | Flush: %s", C_PUR, C_RST, dut.mips_pipelined.dp.instrD, dut.mips_pipelined.dp.rsD, dut.mips_pipelined.dp.rtD, stallD_str, flushD_str);
            $display("  %s[EX]%s   ALUOut: 0x%08h | Flush: %s | EPC: 0x%08h", C_YEL, C_RST, dut.mips_pipelined.dp.aluoutE, flushE_str, dut.mips_pipelined.dp.EPC);
            $display("  %s[MEM]%s  MemWrite: %s | Addr: 0x%08h | WriteData: 0x%08h", C_GRN, C_RST, memwrite_str, dataadr, writedata);
            $display("  %s[WB]%s   RegWrite: %s | RegDst: %2d | ResultW: 0x%08h", C_CYN, C_RST, regwrite_str, dut.mips_pipelined.dp.writeregW, dut.mips_pipelined.dp.resultW);
        end
    end

    always #5 clk = ~clk;

endmodule


`endif // TB_EXCEPTIONS_SV