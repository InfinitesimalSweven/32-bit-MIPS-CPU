`ifndef TB_ALU_SV
`define TB_ALU_SV
`include "_timescale.sv"
`include "alu.sv"

module tb_alu;

    logic        clk;
    logic [31:0] a, b;
    logic [3:0]  alucontrol;
    logic [31:0] result;
    logic        zero;

    int pass = 0, fail = 0;

    alu #(.n(32)) dut (
        .clk(clk),
        .a(a), .b(b),
        .alucontrol(alucontrol),
        .result(result),
        .zero(zero)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check(
        input [31:0] expected_result,
        input        expected_zero,
        input string label
    );
        #10;
        if (result === expected_result && zero === expected_zero) begin
            $display("PASS [%s]: result=%0d zero=%b", label, result, zero);
            pass++;
        end else begin
            $display("FAIL [%s]: got result=%0d zero=%b | expected result=%0d zero=%b",
                     label, result, zero, expected_result, expected_zero);
            fail++;
        end
    endtask

    initial begin
        a = 0; b = 0; alucontrol = 0;

        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alucontrol = 4'b0000; // AND
        check(32'h0F000F00, 0, "AND");

        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alucontrol = 4'b0001; // OR
        check(32'hFF0FFF0F, 0, "OR");

        a = 32'd15; b = 32'd10; alucontrol = 4'b0010; // ADD
        check(32'd25, 0, "ADD basic");

        a = 32'd0; b = 32'd0; alucontrol = 4'b0010; // ADD producing zero
        check(32'd0, 1, "ADD zero flag");

        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alucontrol = 4'b0011; // NOR
        check(32'h00F000F0, 0, "NOR");

        a = 32'd20; b = 32'd10; alucontrol = 4'b0110; // SUB
        check(32'd10, 0, "SUB basic");

        a = 32'd10; b = 32'd10; alucontrol = 4'b0110; // SUB producing zero
        check(32'd0, 1, "SUB zero flag");

        a = 32'd5;  b = 32'd10; alucontrol = 4'b0111; // SLT a < b
        check(32'd1, 0, "SLT a<b");

        a = 32'd10; b = 32'd5;  alucontrol = 4'b0111; // SLT a > b
        check(32'd0, 1, "SLT a>b");

        a = 32'd5;  b = 32'd5;  alucontrol = 4'b0111; // SLT a == b
        check(32'd0, 1, "SLT a==b");

        a = 32'h80000000; b = 32'd1; alucontrol = 4'b0111; // SLT negative vs positive, hits the a[31]!=b[31] branch
        check(32'd1, 0, "SLT negative<positive");

        a = 32'd100; b = 32'd200; alucontrol = 4'b1000; // MULT, triggers on negedge
        @(negedge clk);
        #1;

        alucontrol = 4'b0100; // MFLO reads lower 32 bits of HiLo
        check(32'd20000, 0, "MFLO after MULT");

        alucontrol = 4'b0101; // MFHI reads upper 32 bits, should be 0 for small numbers
        check(32'd0, 1, "MFHI after MULT (small numbers)");

        a = 32'd17; b = 32'd5; alucontrol = 4'b1001; // DIV, triggers on negedge
        @(negedge clk);
        #1;

        alucontrol = 4'b0100; // MFLO reads quotient
        check(32'd3, 0, "MFLO after DIV quotient");

        alucontrol = 4'b0101; // MFHI reads remainder
        check(32'd2, 0, "MFHI after DIV remainder");

        $display("\n=== Results: %0d passed, %0d failed ===", pass, fail);
        $finish;
    end

endmodule
`endif // TB_ALU_SV