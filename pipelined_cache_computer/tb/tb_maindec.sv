`ifndef TB_MAINDEC_SV
`define TB_MAINDEC_SV
`include "_timescale.sv"
`include "maindec.sv"

module tb_maindec;

    logic [5:0] op;
    logic       memtoreg, memwrite;
    logic       branch, alusrc;
    logic       regdst, regwrite;
    logic       jump;
    logic [1:0] aluop;

    int pass = 0, fail = 0;

    maindec dut (
        .op(op),
        .memtoreg(memtoreg), .memwrite(memwrite),
        .branch(branch),     .alusrc(alusrc),
        .regdst(regdst),     .regwrite(regwrite),
        .jump(jump),         .aluop(aluop)
    );

    // exp order: regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, aluop
    task check(
        input logic       exp_regwrite, exp_regdst, exp_alusrc,
        input logic       exp_branch, exp_memwrite, exp_memtoreg,
        input logic       exp_jump,
        input logic [1:0] exp_aluop,
        input string label
    );
        #5;
        if (regwrite === exp_regwrite &&
            regdst   === exp_regdst   &&
            alusrc   === exp_alusrc   &&
            branch   === exp_branch   &&
            memwrite === exp_memwrite &&
            memtoreg === exp_memtoreg &&
            jump     === exp_jump     &&
            aluop    === exp_aluop) begin
            $display("PASS [%s]", label);
            pass++;
        end else begin
            $display("FAIL [%s]:", label);
            $display("  regwrite: got %b exp %b", regwrite, exp_regwrite);
            $display("  regdst:   got %b exp %b", regdst,   exp_regdst);
            $display("  alusrc:   got %b exp %b", alusrc,   exp_alusrc);
            $display("  branch:   got %b exp %b", branch,   exp_branch);
            $display("  memwrite: got %b exp %b", memwrite, exp_memwrite);
            $display("  memtoreg: got %b exp %b", memtoreg, exp_memtoreg);
            $display("  jump:     got %b exp %b", jump,     exp_jump);
            $display("  aluop:    got %b exp %b", aluop,    exp_aluop);
            fail++;
        end
    endtask

    initial begin

        // RTYPE: 000000 -> regwrite=1, regdst=1, alusrc=0, branch=0,
        //                   memwrite=0, memtoreg=0, jump=0, aluop=10
        op = 6'b000000;
        check(1, 1, 0, 0, 0, 0, 0, 2'b10, "RTYPE");

        // LW: 100011 -> regwrite=1, regdst=0, alusrc=1, branch=0,
        //               memwrite=0, memtoreg=1, jump=0, aluop=00
        op = 6'b100011;
        check(1, 0, 1, 0, 0, 1, 0, 2'b00, "LW");

        // SW: 101011 -> regwrite=0, regdst=0, alusrc=1, branch=0,
        //               memwrite=1, memtoreg=0, jump=0, aluop=00
        op = 6'b101011;
        check(0, 0, 1, 0, 1, 0, 0, 2'b00, "SW");

        // BEQ: 000100 -> regwrite=0, regdst=0, alusrc=0, branch=1,
        //                memwrite=0, memtoreg=0, jump=0, aluop=01
        op = 6'b000100;
        check(0, 0, 0, 1, 0, 0, 0, 2'b01, "BEQ");

        // ADDI: 001000 -> regwrite=1, regdst=0, alusrc=1, branch=0,
        //                 memwrite=0, memtoreg=0, jump=0, aluop=00
        op = 6'b001000;
        check(1, 0, 1, 0, 0, 0, 0, 2'b00, "ADDI");

        // J: 000010 -> regwrite=0, regdst=0, alusrc=0, branch=0,
        //              memwrite=0, memtoreg=0, jump=1, aluop=00
        op = 6'b000010;
        check(0, 0, 0, 0, 0, 0, 1, 2'b00, "JUMP");

        // ILLEGAL/DEFAULT: should output all zeros (NOP)
        op = 6'b111111;
        check(0, 0, 0, 0, 0, 0, 0, 2'b00, "ILLEGAL OP -> NOP");

        op = 6'b010101;
        check(0, 0, 0, 0, 0, 0, 0, 2'b00, "ILLEGAL OP 2 -> NOP");

        $display("\n=== Results: %0d passed, %0d failed ===", pass, fail);
        $finish;
    end

endmodule
`endif // TB_MAINDEC_SV