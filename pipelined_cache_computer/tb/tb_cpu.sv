`include "_timescale.sv"
`include "src/cpu.sv"

module tb_cpu;

    // Clock & control
    logic        clk, reset, intr, mem_stall;

    // Instruction memory interface
    logic [31:0] pcF;
    logic [31:0] instrF;

    // Data memory interface
    logic        memwriteM, memreadM;
    logic [31:0] aluoutM, writedataM, readdataM;

    // -------------------------------------------------------
    // DUT
    // -------------------------------------------------------
    cpu dut (
        .clk(clk), .reset(reset), .intr(intr), .mem_stall(mem_stall),
        .pcF(pcF), .instrF(instrF),
        .memwriteM(memwriteM), .memreadM(memreadM),
        .aluoutM(aluoutM), .writedataM(writedataM), .readdataM(readdataM)
    );

    // -------------------------------------------------------
    // Clock — 10 ns period
    // -------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------
    // Instruction memory (ROM)
    //
    // Program:
    //   0:  addi $t0, $zero, 5      $t0 = 5
    //   1:  addi $t1, $zero, 7      $t1 = 7
    //   2:  add  $t2, $t0,   $t1    $t2 = 12
    //   3:  sw   $t2, 0($zero)      mem[0] = 12
    //   4:  lw   $t3, 0($zero)      $t3 = mem[0] = 12
    //   5:  beq  $t3, $t2,  +1      branch taken (t3==t2)
    //   6:  addi $t0, $zero, 99     ** skipped **
    //   7:  addi $s0, $zero, 1      $s0 = 1
    //   8:  j    0                  loop forever (acts as halt)
    // -------------------------------------------------------
    logic [31:0] imem [0:15];

    initial begin
        imem[0]  = 32'h20080005; // addi $t0, $zero, 5
        imem[1]  = 32'h20090007; // addi $t1, $zero, 7
        imem[2]  = 32'h01095020; // add  $t2, $t0, $t1
        imem[3]  = 32'hAC0A0000; // sw   $t2, 0($zero)
        imem[4]  = 32'h8C0B0000; // lw   $t3, 0($zero)
        imem[5]  = 32'h116A0001; // beq  $t3, $t2, +1
        imem[6]  = 32'h20080063; // addi $t0, $zero, 99  (skipped)
        imem[7]  = 32'h20100001; // addi $s0, $zero, 1
        imem[8]  = 32'h08000000; // j    0
        // pad remainder with NOPs
        imem[9]  = 32'h00000000;
        imem[10] = 32'h00000000;
        imem[11] = 32'h00000000;
        imem[12] = 32'h00000000;
        imem[13] = 32'h00000000;
        imem[14] = 32'h00000000;
        imem[15] = 32'h00000000;
    end

    // word-addressed fetch
    assign instrF = imem[pcF[5:2]];

    // -------------------------------------------------------
    // Data memory (RAM, 64 words)
    // -------------------------------------------------------
    logic [31:0] dmem [0:63];

    initial foreach (dmem[i]) dmem[i] = 32'h0;

    // synchronous write
    always_ff @(posedge clk) begin
        if (memwriteM)
            dmem[aluoutM[7:2]] <= writedataM;
    end

    // combinational read
    assign readdataM = memreadM ? dmem[aluoutM[7:2]] : 32'hDEADBEEF;

    // -------------------------------------------------------
    // Defaults
    // -------------------------------------------------------
    initial begin
        intr      = 0;
        mem_stall = 0;
    end

    // -------------------------------------------------------
    // Cycle counter for display / timeout
    // -------------------------------------------------------
    integer cycle = 0;
    always_ff @(posedge clk) cycle <= cycle + 1;

    // -------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------
    initial begin
        $dumpfile("tb_cpu.vcd");
        $dumpvars(0, tb_cpu);

        // Reset for 2 cycles
        reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk); reset = 0;
        $display("[%0t] Reset released", $time);

        // ----------------------------------------
        // Let pipeline drain — 20 cycles is enough
        // for 9 instructions + pipeline depth
        // ----------------------------------------
        repeat (20) @(posedge clk);

        // ----------------------------------------
        // TEST 1: data memory write
        //   sw $t2, 0($zero) should store 12
        // ----------------------------------------
        if (dmem[0] === 32'd12)
            $display("PASS TEST 1: dmem[0] = %0d (expected 12)", dmem[0]);
        else
            $display("FAIL TEST 1: dmem[0] = %0d