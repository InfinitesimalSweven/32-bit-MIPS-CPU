`ifndef TB_CONTROLLER_SV
`define TB_CONTROLLER_SV
`include "_timescale.sv"
`include "controller.sv"

module tb_controller;

    logic [5:0] opD, functD;
    logic       memtoregD, memwriteD, alusrcD, regdstD, regwriteD;
    logic       branchD, jumpD;
    logic [3:0] alucontrolD;

    int pass = 0, fail = 0;

    controller dut (
        .opD(opD), .functD(functD),
        .memtoregD(memtoregD), .memwriteD(memwriteD),
        .alusrcD(alusrcD), .regdstD(regdstD), .regwriteD(regwriteD),
        .branchD(branchD), .jumpD(jumpD),
        .alucontrolD(alucontrolD)
    );

    task check(
        input logic exp_memtoreg, exp_memwrite, exp_alusrc,
                    exp_regdst,  exp_regwrite, exp_branch, exp_jump,
        input logic [3:0] exp_alucontrol,
        input string label
    );
        #10;
        if (memtoregD  === exp_memtoreg  &&
            memwriteD  === exp_memwrite  &&
            alusrcD    === exp_alusrc    &&
            regdstD    === exp_regdst    &&
            regwriteD  === exp_regwrite  &&
            branchD    === exp_branch    &&
            jumpD      === exp_jump      &&
            alucontrolD=== exp_alucontrol) begin
            $display("PASS [%s]: alucontrol=%b", label, alucontrolD);
            pass++;
        end else begin
            $display("FAIL [%s]:", label);
            $display("  memtoreg: got %b exp %b", memtoregD,   exp_memtoreg);
            $display("  memwrite: got %b exp %b", memwriteD,   exp_memwrite);
            $display("  alusrc:   got %b exp %b", alusrcD,     exp_alusrc);
            $display("  regdst:   got %b exp %b", regdstD,     exp_regdst);
            $display("  regwrite: got %b exp %b", regwriteD,   exp_regwrite);
            $display("  branch:   got %b exp %b", branchD,     exp_branch);
            $display("  jump:     got %b exp %b", jumpD,        exp_jump);
            $display("  aluctl:   got %b exp %b", alucontrolD, exp_alucontrol);
            fail++;
        end
    endtask

    initial begin
        // R-type ADD (op=000000, funct=100000)
        opD = 6'b000000; functD = 6'b100000;
        check(0, 0, 0, 1, 1, 0, 0, 4'b0010, "R-type ADD");

        // R-type SUB (op=000000, funct=100010)
        opD = 6'b000000; functD = 6'b100010;
        check(0, 0, 0, 1, 1, 0, 0, 4'b0110, "R-type SUB");

        // R-type AND (op=000000, funct=100100)
        opD = 6'b000000; functD = 6'b100100;
        check(0, 0, 0, 1, 1, 0, 0, 4'b0000, "R-type AND");

        // R-type OR (op=000000, funct=100101)
        opD = 6'b000000; functD = 6'b100101;
        check(0, 0, 0, 1, 1, 0, 0, 4'b0001, "R-type OR");

        // R-type SLT (op=000000, funct=101010)
        opD = 6'b000000; functD = 6'b101010;
        check(0, 0, 0, 1, 1, 0, 0, 4'b0111, "R-type SLT");

        // lw (op=100011)
        opD = 6'b100011; functD = 6'bxxxxxx;
        check(1, 0, 1, 0, 1, 0, 0, 4'b0010, "LW");

        // sw (op=101011)
        opD = 6'b101011; functD = 6'bxxxxxx;
        check(0, 1, 1, 0, 0, 0, 0, 4'b0010, "SW");

        // beq (op=000100)
        opD = 6'b000100; functD = 6'bxxxxxx;
        check(0, 0, 0, 0, 0, 1, 0, 4'b0110, "BEQ");

        // addi (op=001000)
        opD = 6'b001000; functD = 6'bxxxxxx;
        check(0, 0, 1, 0, 1, 0, 0, 4'b0010, "ADDI");

        // j (op=000010)
        opD = 6'b000010; functD = 6'bxxxxxx;
        check(0, 0, 0, 0, 0, 0, 1, 4'b0010, "JUMP");
        $display("\n=== Results: %0d passed, %0d failed ===", pass, fail);
        $finish;
    end

endmodule
`endif // TB_CONTROLLER_SV