with open("tb_computer.sv", "r") as f:
    content = f.read()

old_block = """    // Cycle-by-cycle logging for educational trace routing
    integer cycle = 0;
    always @(posedge clk) begin
        if (!reset) begin
            cycle++;
            $display("-----------------------------------------------------");
            $display("Cycle %0d (Time: %0t)", cycle, $time);
            $display("  [IF]   PC: 0x%08h | StallF: %b", 
                     dut.mips_pipelined.dp.pcF, dut.mips_pipelined.stallF);
            $display("  [ID]   Instr: 0x%08h | rs: %0d, rt: %0d | StallD: %b | FlushD: %b | Branch: %b", 
                     dut.mips_pipelined.dp.instrD, dut.mips_pipelined.dp.rsD, dut.mips_pipelined.dp.rtD, 
                     dut.mips_pipelined.stallD, dut.mips_pipelined.flushD, dut.mips_pipelined.branchD);
            $display("  [EX]   ALUOut: 0x%08h | FlushE: %b | EPC: 0x%08h", 
                     dut.mips_pipelined.dp.aluoutE, dut.mips_pipelined.flushE, dut.mips_pipelined.dp.EPC);
            $display("  [MEM]  MemWrite: %b | Addr: 0x%08h | WriteData: 0x%08h", 
                     memwrite, dataadr, writedata);
            $display("  [WB]   RegWrite: %b | RegDst: %0d | ResultW: 0x%08h", 
                     dut.mips_pipelined.dp.regwriteW, dut.mips_pipelined.dp.writeregW, dut.mips_pipelined.dp.resultW);
        end
    end"""

new_block = """    // Cycle-by-cycle logging for educational trace routing
    integer cycle = 0;
    always @(posedge clk) begin
        if (!reset) begin
            cycle++;
            $display("╭─────────────────────────────────────────────────────────────────────────────────────────────────╮");
            $display("│ %-95s │", $sformatf("Cycle %0d (Time: %0t)", cycle, $time));
            $display("│ %-95s │", $sformatf("  [IF]   PC: 0x%08h | StallF: %b", dut.mips_pipelined.dp.pcF, dut.mips_pipelined.stallF));
            $display("│ %-95s │", $sformatf("  [ID]   Instr: 0x%08h | rs: %2d, rt: %2d | StallD: %b | FlushD: %b | Branch: %b", dut.mips_pipelined.dp.instrD, dut.mips_pipelined.dp.rsD, dut.mips_pipelined.dp.rtD, dut.mips_pipelined.stallD, dut.mips_pipelined.flushD, dut.mips_pipelined.branchD));
            $display("│ %-95s │", $sformatf("  [EX]   ALUOut: 0x%08h | FlushE: %b | EPC: 0x%08h", dut.mips_pipelined.dp.aluoutE, dut.mips_pipelined.flushE, dut.mips_pipelined.dp.EPC));
            $display("│ %-95s │", $sformatf("  [MEM]  MemWrite: %b | Addr: 0x%08h | WriteData: 0x%08h", memwrite, dataadr, writedata));
            $display("│ %-95s │", $sformatf("  [WB]   RegWrite: %b | RegDst: %2d | ResultW: 0x%08h", dut.mips_pipelined.dp.regwriteW, dut.mips_pipelined.dp.writeregW, dut.mips_pipelined.dp.resultW));
            $display("╰─────────────────────────────────────────────────────────────────────────────────────────────────╯");
        end
    end"""

if old_block in content:
    with open("tb_computer.sv", "w") as f:
        f.write(content.replace(old_block, new_block))
    print("Replaced successfully")
else:
    print("Old block not found!")