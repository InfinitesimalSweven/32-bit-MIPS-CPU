`ifndef TB_HAZARD_SV
`define TB_HAZARD_SV
`include "_timescale.sv"
`include "hazard.sv"

module tb_hazard;

    logic [4:0] rsD, rtD, rsE, rtE;
    logic [4:0] writeregE, writeregM, writeregW;
    logic       regwriteE, regwriteM, regwriteW;
    logic       memtoregE, memtoregM;
    logic       branchD, intr, mem_stall;

    logic       forwardaD, forwardbD;
    logic [1:0] forwardaE, forwardbE;
    logic       stallF, stallD, stallE, stallM, stallW, flushD, flushE;
    logic       Exception_Flag;

    int pass = 0, fail = 0;

    hazard dut (
        .rsD(rsD), .rtD(rtD), .rsE(rsE), .rtE(rtE),
        .writeregE(writeregE), .writeregM(writeregM), .writeregW(writeregW),
        .regwriteE(regwriteE), .regwriteM(regwriteM), .regwriteW(regwriteW),
        .memtoregE(memtoregE), .memtoregM(memtoregM),
        .branchD(branchD), .intr(intr), .mem_stall(mem_stall),
        .forwardaD(forwardaD), .forwardbD(forwardbD),
        .forwardaE(forwardaE), .forwardbE(forwardbE),
        .stallF(stallF), .stallD(stallD), .stallE(stallE),
        .stallM(stallM), .stallW(stallW),
        .flushD(flushD), .flushE(flushE),
        .Exception_Flag(Exception_Flag)
    );

    task check(
        input logic       exp_forwardaD, exp_forwardbD,
        input logic [1:0] exp_forwardaE, exp_forwardbE,
        input logic       exp_stallF, exp_stallD, exp_flushE,
        input logic       exp_exception,
        input string label
    );
        #5;
        if (forwardaD      === exp_forwardaD &&
            forwardbD      === exp_forwardbD &&
            forwardaE      === exp_forwardaE &&
            forwardbE      === exp_forwardbE &&
            stallF         === exp_stallF    &&
            stallD         === exp_stallD    &&
            flushE         === exp_flushE    &&
            Exception_Flag === exp_exception) begin
            $display("PASS [%s]", label);
            pass++;
        end else begin
            $display("FAIL [%s]:", label);
            $display("  forwardaD: got %b exp %b", forwardaD, exp_forwardaD);
            $display("  forwardbD: got %b exp %b", forwardbD, exp_forwardbD);
            $display("  forwardaE: got %b exp %b", forwardaE, exp_forwardaE);
            $display("  forwardbE: got %b exp %b", forwardbE, exp_forwardbE);
            $display("  stallF:    got %b exp %b", stallF,    exp_stallF);
            $display("  stallD:    got %b exp %b", stallD,    exp_stallD);
            $display("  flushE:    got %b exp %b", flushE,    exp_flushE);
            $display("  exception: got %b exp %b", Exception_Flag, exp_exception);
            fail++;
        end
    endtask

    initial begin
        // initialize all inputs to safe defaults
        rsD=0; rtD=0; rsE=0; rtE=0;
        writeregE=0; writeregM=0; writeregW=0;
        regwriteE=0; regwriteM=0; regwriteW=0;
        memtoregE=0; memtoregM=0;
        branchD=0; intr=0; mem_stall=0;

        // no hazard: all different registers, no stalls or forwards expected
        rsE=5'd1; rtE=5'd2; writeregM=5'd5; writeregW=5'd6;
        regwriteM=1; regwriteW=1;
        rsD=5'd3; rtD=5'd4; writeregE=5'd7; regwriteE=1;
        check(0, 0, 2'b00, 2'b00, 0, 0, 0, 0, "NO HAZARD");

        // EX-MEM forwarding: rsE matches writeregM
        rsD=5'd9; rtD=5'd9;
        rsE=5'd3; rtE=5'd2; writeregM=5'd3; regwriteM=1;
        writeregW=5'd9; regwriteW=1;
        check(0, 0, 2'b10, 2'b00, 0, 0, 0, 0, "FORWARD aE from MEM stage");

        // EX-MEM forwarding: rtE matches writeregM
        rsD=5'd9; rtD=5'd9;
        rsE=5'd1; rtE=5'd3; writeregM=5'd3; regwriteM=1;
        check(0, 0, 2'b00, 2'b10, 0, 0, 0, 0, "FORWARD bE from MEM stage");

        // MEM-WB forwarding: rsE matches writeregW (no MEM match)
        rsD=5'd1; rtD=5'd2;  // FIX: keep rsD/rtD away from writeregM=9
        rsE=5'd5; rtE=5'd2; writeregM=5'd9; writeregW=5'd5;
        regwriteM=1; regwriteW=1;
        check(0, 0, 2'b01, 2'b00, 0, 0, 0, 0, "FORWARD aE from WB stage");

        // MEM-WB forwarding: rtE matches writeregW
        rsD=5'd1; rtD=5'd2;  // FIX: keep rsD/rtD away from writeregM=9
        rsE=5'd1; rtE=5'd5; writeregM=5'd9; writeregW=5'd5;
        regwriteM=1; regwriteW=1;
        check(0, 0, 2'b00, 2'b01, 0, 0, 0, 0, "FORWARD bE from WB stage");

        // decode forwarding: rsD matches writeregM
        rsD=5'd3; rtD=5'd4; writeregM=5'd3; regwriteM=1;
        rsE=5'd1; rtE=5'd2;
        check(1, 0, 2'b00, 2'b00, 0, 0, 0, 0, "FORWARD aD from MEM stage");

        // decode forwarding: rtD matches writeregM
        rsD=5'd1; rtD=5'd3; writeregM=5'd3; regwriteM=1;
        check(0, 1, 2'b00, 2'b00, 0, 0, 0, 0, "FORWARD bD from MEM stage");

        // load-use stall: lw in execute, dependent instruction in decode
        rsD=5'd4; rtD=5'd5; rsE=5'd1; rtE=5'd4;
        memtoregE=1; regwriteM=0; writeregM=0;
        branchD=0;
        check(0, 0, 2'b00, 2'b00, 1, 1, 1, 0, "LOAD-USE STALL rtE==rsD");

        // load-use stall: rtE matches rtD
        rsD=5'd1; rtD=5'd4; rtE=5'd4;
        memtoregE=1;
        check(0, 0, 2'b00, 2'b00, 1, 1, 1, 0, "LOAD-USE STALL rtE==rtD");

        // no stall when registers are zero (r0 hardwired, forwarding skipped)
        memtoregE=0;
        rsD=5'd0; rtD=5'd0; rtE=5'd0; rsE=5'd0;
        writeregM=5'd0; regwriteM=1;
        check(0, 0, 2'b00, 2'b00, 0, 0, 0, 0, "NO HAZARD r0 never forwarded");

        // exception/interrupt: intr asserted
        rsD=0; rtD=0; rsE=0; rtE=0;
        memtoregE=0; branchD=0; mem_stall=0;
        intr=1;
        check(0, 0, 2'b00, 2'b00, 0, 0, 1, 1, "EXCEPTION flushE and Exception_Flag");
        intr=0;

        // mem_stall: cache miss stalls entire pipeline
        mem_stall=1;
        check(0, 0, 2'b00, 2'b00, 1, 1, 0, 0, "MEM STALL freezes pipeline");
        mem_stall=0;

        $display("\n=== Results: %0d passed, %0d failed ===", pass, fail);
        $finish;
    end

endmodule
`endif // TB_HAZARD_SV