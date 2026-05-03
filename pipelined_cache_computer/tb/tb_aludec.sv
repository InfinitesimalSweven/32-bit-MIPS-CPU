`ifndef TB_ALUDEC_SV
`define TB_ALUDEC_SV
`include "_timescale.sv"
`include "aludec.sv"

module tb_aludec;

    logic [5:0] funct;
    logic [1:0] aluop;
    logic [3:0] alucontrol;

    int pass = 0, fail = 0;

    aludec dut (
        .funct(funct),
        .aluop(aluop),
        .alucontrol(alucontrol)
    );

    task check(
        input logic [3:0] exp_alucontrol,
        input string label
    );
        #5;
        if (alucontrol === exp_alucontrol) begin
            $display("PASS [%s]: alucontrol = %b", label, alucontrol);
            pass++;
        end else begin
            $display("FAIL [%s]: got %b, exp %b", label, alucontrol, exp_alucontrol);
            fail++;
        end
    endtask

    initial begin

        // -------------------------------------------------------
        // aluop = 00: always ADD regardless of funct
        // -------------------------------------------------------
        aluop = 2'b00; funct = 6'b000000;
        check(4'b0010, "ALUOP=00 funct=000000 -> ADD");

        aluop = 2'b00; funct = 6'b100010; // sub funct, but aluop overrides
        check(4'b0010, "ALUOP=00 funct=sub   -> ADD (override)");

        aluop = 2'b00; funct = 6'b101010; // slt funct, but aluop overrides
        check(4'b0010, "ALUOP=00 funct=slt   -> ADD (override)");

        // -------------------------------------------------------
        // aluop = 01: always SUB regardless of funct (BEQ)
        // -------------------------------------------------------
        aluop = 2'b01; funct = 6'b000000;
        check(4'b0110, "ALUOP=01 funct=000000 -> SUB");

        aluop = 2'b01; funct = 6'b100000; // add funct, but aluop overrides
        check(4'b0110, "ALUOP=01 funct=add   -> SUB (override)");

        // -------------------------------------------------------
        // aluop = 10: R-type, decode from funct
        // -------------------------------------------------------
        aluop = 2'b10;

        funct = 6'b100000;
        check(4'b0010, "RTYPE add  (100000) -> 0010");

        funct = 6'b100010;
        check(4'b0110, "RTYPE sub  (100010) -> 0110");

        funct = 6'b100100;
        check(4'b0000, "RTYPE and  (100100) -> 0000");

        funct = 6'b100101;
        check(4'b0001, "RTYPE or   (100101) -> 0001");

        funct = 6'b101010;
        check(4'b0111, "RTYPE slt  (101010) -> 0111");

        funct = 6'b011000;
        check(4'b1000, "RTYPE mult (011000) -> 1000");

        funct = 6'b011010;
        check(4'b1001, "RTYPE div  (011010) -> 1001");

        funct = 6'b010010;
        check(4'b0100, "RTYPE mflo (010010) -> 0100");

        funct = 6'b010000;
        check(4'b0101, "RTYPE mfhi (010000) -> 0101");

        // -------------------------------------------------------
        // aluop = 10: R-type unknown funct -> default ADD
        // -------------------------------------------------------
        funct = 6'b111111;
        check(4'b0010, "RTYPE unknown funct -> default ADD");

        funct = 6'b000001;
        check(4'b0010, "RTYPE unknown funct 2 -> default ADD");

        // -------------------------------------------------------
        // aluop = 11: not defined, hits default -> R-type decode
        //             with unknown funct -> ADD
        // -------------------------------------------------------
        aluop = 2'b11; funct = 6'b111111;
        check(4'b0010, "ALUOP=11 unknown -> default ADD");

        $display("\n=== Results: %0d passed, %0d failed ===", pass, fail);
        $finish;
    end

endmodule
`endif // TB_ALUDEC_SV