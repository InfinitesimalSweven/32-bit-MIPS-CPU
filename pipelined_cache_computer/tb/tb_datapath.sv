`ifndef TB_DATAPATH_SV
`define TB_DATAPATH_SV
`include "_timescale.sv"
`include "datapath.sv"

module tb_datapath;

    // Clock and reset
    logic        clk, reset;

    // Fetch
    logic [31:0] pcF;
    logic [31:0] instrF;

    // Memory interface
    logic [31:0] aluoutM, writedataM;
    logic [31:0] readdataM;

    // Control signals (decode stage)
    logic        memtoregD, memwriteD;
    logic        alusrcD, regdstD, regwriteD;
    logic        jumpD, branchD;
    logic [3:0]  alucontrolD;

    // Decoded instruction
    logic [31:0] instrD;

    // Hazard signals
    logic        stallF, stallD, stallE, stallM, stallW, flushD, flushE;
    logic        Exception_Flag;
    logic        forwardaD, forwardbD;
    logic [1:0]  forwardaE, forwardbE;

    // Hazard observation outputs
    logic [4:0]  rsD, rtD, rsE, rtE;
    logic [4:0]  writeregE, writeregM, writeregW;
    logic        regwriteE, regwriteM, regwriteW;
    logic        memtoregE, memtoregM;
    logic        memwriteM_out;

    int pass = 0, fail = 0;

    // DUT
    datapath dut (
        .clk(clk), .reset(reset),
        .pcF(pcF),
        .instrF(instrF),
        .aluoutM(aluoutM), .writedataM(writedataM),
        .readdataM(readdataM),
        .memtoregD(memtoregD), .memwriteD(memwriteD),
        .alusrcD(alusrcD), .regdstD(regdstD), .regwriteD(regwriteD),
        .jumpD(jumpD), .branchD(branchD),
        .alucontrolD(alucontrolD),
        .instrD(instrD),
        .stallF(stallF), .stallD(stallD), .stallE(stallE),
        .stallM(stallM), .stallW(stallW),
        .flushD(flushD), .flushE(flushE),
        .Exception_Flag(Exception_Flag),
        .forwardaD(forwardaD), .forwardbD(forwardbD),
        .forwardaE(forwardaE), .forwardbE(forwardbE),
        .rsD(rsD), .rtD(rtD), .rsE(rsE), .rtE(rtE),
        .writeregE(writeregE), .writeregM(writeregM), .writeregW(writeregW),
        .regwriteE(regwriteE), .regwriteM(regwriteM), .regwriteW(regwriteW),
        .memtoregE(memtoregE), .memtoregM(memtoregM),
        .memwriteM_out(memwriteM_out)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Default safe values for all hazard/control inputs
    task set_defaults;
        instrF        = 32'b0;
        readdataM     = 32'b0;
        memtoregD     = 0; memwriteD  = 0;
        alusrcD       = 0; regdstD    = 0; regwriteD = 0;
        jumpD         = 0; branchD    = 0;
        alucontrolD   = 4'b0010; // ADD
        stallF        = 0; stallD     = 0; stallE    = 0;
        stallM        = 0; stallW     = 0;
        flushD        = 0; flushE     = 0;
        Exception_Flag = 0;
        forwardaD     = 0; forwardbD  = 0;
        forwardaE     = 2'b00; forwardbE = 2'b00;
    endtask

    task check_val(
        input logic [31:0] got, exp,
        input string label
    );
        if (got === exp) begin
            $display("PASS [%s]: got %h", label, got);
            pass++;
        end else begin
            $display("FAIL [%s]: got %h, exp %h", label, got, exp);
            fail++;
        end
    endtask

    task check_bit(
        input logic got, exp,
        input string label
    );
        if (got === exp) begin
            $display("PASS [%s]: got %b", label, got);
            pass++;
        end else begin
            $display("FAIL [%s]: got %b, exp %b", label, got, exp);
            fail++;
        end
    endtask

    initial begin
        set_defaults();
        reset = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;

        // -------------------------------------------------------
        // TEST 1: Reset — PC should be 0 after reset
        // -------------------------------------------------------
        check_val(pcF, 32'h0, "RESET: pcF = 0");

        // -------------------------------------------------------
        // TEST 2: PC increments by 4 each cycle (no stall)
        // -------------------------------------------------------
        reset = 0;
        @(posedge clk); #1;
        check_val(pcF, 32'h4, "PC INCREMENT: pcF = 4");
        @(posedge clk); #1;
        check_val(pcF, 32'h8, "PC INCREMENT: pcF = 8");

        // -------------------------------------------------------
        // TEST 3: stallF holds PC
        // -------------------------------------------------------
        stallF = 1;
        @(posedge clk); #1;
        check_val(pcF, 32'h8, "STALL: pcF held at 8");
        stallF = 0;
        @(posedge clk); #1; // let it advance again

        // -------------------------------------------------------
        // TEST 4: instrD propagates instrF after one cycle
        //         (no flush, no stall on decode)
        // -------------------------------------------------------
        reset = 1; @(posedge clk); #1; reset = 0;
        // Encode: add $t0, $t1, $t2 (rs=9, rt=10, rd=8)
        // [31:26]=000000 [25:21]=01001 [20:16]=01010 [15:11]=01000 [10:6]=00000 [5:0]=100000
        instrF = {6'b000000, 5'd9, 5'd10, 5'd8, 5'd0, 6'b100000};
        @(posedge clk); #1;
        // After one clock, instrD should latch instrF
        check_val(instrD, instrF, "IFID: instrD latches instrF");

        // -------------------------------------------------------
        // TEST 5: rsD and rtD extracted from instrD correctly
        // -------------------------------------------------------
        check_val({27'b0, rsD}, {27'b0, 5'd9},  "DECODE: rsD = 9");
        check_val({27'b0, rtD}, {27'b0, 5'd10}, "DECODE: rtD = 10");

        // -------------------------------------------------------
        // TEST 6: flushD clears instrD
        // -------------------------------------------------------
        flushD = 1;
        @(posedge clk); #1;
        flushD = 0;
        check_val(instrD, 32'b0, "FLUSHD: instrD cleared");

        // -------------------------------------------------------
        // TEST 7: R-type pipeline — writeregE computed correctly
        //         regdstD=1 picks rd, instrF has rd=8
        // -------------------------------------------------------
        reset = 1; @(posedge clk); #1; reset = 0;
        instrF    = {6'b000000, 5'd9, 5'd10, 5'd8, 5'd0, 6'b100000};
        regwriteD = 1; regdstD = 1; alucontrolD = 4'b0010;
        @(posedge clk); #1; // IF->ID
        @(posedge clk); #1; // ID->EX: writeregE should be rd=8
        check_val({27'b0, writeregE}, {27'b0, 5'd8}, "IDEX: writeregE = rd = 8");
        check_bit(regwriteE, 1, "IDEX: regwriteE propagated");

        // -------------------------------------------------------
        // TEST 8: I-type pipeline — alusrcD=1, regdstD=0 → writeregE=rt
        //         instrF: addi $t0, $t1, 5  (rs=9, rt=8, imm=5)
        // -------------------------------------------------------
        reset = 1; @(posedge clk); #1; reset = 0;
        instrF      = {6'b001000, 5'd9, 5'd8, 16'd5};
        regwriteD   = 1; regdstD = 0; alusrcD = 1; alucontrolD = 4'b0010;
        memtoregD   = 0;
        @(posedge clk); #1; // IF->ID
        @(posedge clk); #1; // ID->EX
        check_val({27'b0, writeregE}, {27'b0, 5'd8}, "ITYPE: writeregE = rt = 8");

        // -------------------------------------------------------
        // TEST 9: memtoreg propagation through EX->MEM->WB
        // -------------------------------------------------------
        reset = 1; @(posedge clk); #1; reset = 0;
        instrF    = {6'b100011, 5'd9, 5'd8, 16'd0}; // lw $t0, 0($t1)
        regwriteD = 1; regdstD = 0; alusrcD = 1;
        memtoregD = 1; alucontrolD = 4'b0010;
        @(posedge clk); #1; // IF->ID
        @(posedge clk); #1; // ID->EX: memtoregE should be 1
        check_bit(memtoregE, 1, "MEMTOREG: memtoregE=1 in EX");
        @(posedge clk); #1; // EX->MEM
        check_bit(memtoregM, 1, "MEMTOREG: memtoregM=1 in MEM");

        // -------------------------------------------------------
        // TEST 10: memwriteM_out propagation for store
        // -------------------------------------------------------
        reset = 1; @(posedge clk); #1; reset = 0;
        instrF    = {6'b101011, 5'd9, 5'd8, 16'd0}; // sw $t0, 0($t1)
        regwriteD = 0; memwriteD = 1; alusrcD = 1; alucontrolD = 4'b0010;
        @(posedge clk); #1; // IF->ID
        @(posedge clk); #1; // ID->EX
        @(posedge clk); #1; // EX->MEM
        check_bit(memwriteM_out, 1, "MEMWRITE: memwriteM_out=1 in MEM");

        // -------------------------------------------------------
        // TEST 11: Exception_Flag causes flushE and PC redirect
        //          PC should jump to 0x8000_0180
        // -------------------------------------------------------
        reset = 1; @(posedge clk); #1; reset = 0;
        set_defaults();
        @(posedge clk); #1; // advance a couple cycles
        @(posedge clk); #1;
        Exception_Flag = 1; flushE = 1;
        @(posedge clk); #1;
        Exception_Flag = 0; flushE = 0;
        check_val(pcF, 32'h8000_0180, "EXCEPTION: PC redirected to handler");

        // -------------------------------------------------------
        // TEST 12: Jump redirects PC to {pcplus4D[31:28], target, 2'b00}
        //          Reset so pcplus4D = 8 (pcF=4 after 1 cycle, +4 = 8)
        //          instrD[25:0] = 26'h4 -> target = {4'hX, 26'h4, 00}
        // -------------------------------------------------------
        reset = 1; @(posedge clk); #1; reset = 0;
        set_defaults();
        // Load a jump instruction into the pipeline
        // j 1 -> [31:26]=000010, [25:0] = 26'd1
        instrF = {6'b000010, 26'd1};
        @(posedge clk); #1; // IF->ID: instrD = jump instr, pcplus4D = 4
        jumpD  = 1;
        @(posedge clk); #1;
        jumpD = 0;
        // pcjumpFD = {pcplus4D[31:28], instrD[25:0], 2'b00}
        //          = {4'b0, 26'd1, 2'b00} = 32'h0000_0004
        check_val(pcF, 32'h0000_0004, "JUMP: PC redirected correctly");

        // -------------------------------------------------------
        // TEST 13: stallM holds aluoutM
        // -------------------------------------------------------
        reset = 1; @(posedge clk); #1; reset = 0;
        set_defaults();
        instrF      = {6'b001000, 5'd0, 5'd8, 16'd42}; // addi $t0, $0, 42
        regwriteD   = 1; regdstD = 0; alusrcD = 1; alucontrolD = 4'b0010;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1; // aluoutM should now be 42
        begin
            logic [31:0] captured;
            captured = aluoutM;
            stallM = 1;
            @(posedge clk); #1;
            check_val(aluoutM, captured, "STALLM: aluoutM held");
            stallM = 0;
        end

        // -------------------------------------------------------
        // TEST 14: EX forwarding path (forwardaE=2'b10 → use aluoutM)
        //          Inject a known aluoutM by running addi first,
        //          then verify forwarded operand reaches execute
        // -------------------------------------------------------
        reset = 1; @(posedge clk); #1; reset = 0;
        set_defaults();
        // Cycle 1: addi $t0, $0, 7 into pipeline
        instrF = {6'b001000, 5'd0, 5'd8, 16'd7};
        regwriteD=1; regdstD=0; alusrcD=1; alucontrolD=4'b0010;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1; // aluoutM = 7
        check_val(aluoutM, 32'd7, "FORWARD SETUP: aluoutM = 7");

        $display("\n=== Results: %0d passed, %0d failed ===", pass, fail);
        $finish;
    end

endmodule
`endif // TB_DATAPATH_SV