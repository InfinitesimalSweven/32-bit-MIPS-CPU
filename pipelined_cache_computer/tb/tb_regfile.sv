`ifndef TB_REGFILE_SV
`define TB_REGFILE_SV
`include "_timescale.sv"
`include "regfile.sv"

module tb_regfile;

    logic        clk, we3;
    logic [4:0]  ra1, ra2, wa3;
    logic [31:0] wd3;
    logic [31:0] rd1, rd2;

    int pass = 0, fail = 0;

    regfile dut (
        .clk(clk), .we3(we3),
        .ra1(ra1), .ra2(ra2), .wa3(wa3),
        .wd3(wd3),
        .rd1(rd1), .rd2(rd2)
    );

    // Clock: 10ns period, writes on negedge
    initial clk = 0;
    always #5 clk = ~clk;

    task check32(
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

    // Write a value and wait for negedge to commit
    task write_reg(input logic [4:0] reg_addr, input logic [31:0] data);
        @(posedge clk); #1;
        wa3 = reg_addr;
        wd3 = data;
        we3 = 1;
        @(negedge clk); #1; // write commits here
        we3 = 0;
    endtask

    initial begin
        // safe defaults
        we3 = 0; ra1 = 0; ra2 = 0; wa3 = 0; wd3 = 0;

        // let reset settle
        @(posedge clk); #1;

        // -------------------------------------------------------
        // TEST 1: r0 always reads 0, even if we try to write it
        // -------------------------------------------------------
        wa3 = 5'd0; wd3 = 32'hDEADBEEF; we3 = 1;
        @(negedge clk); #1;
        we3 = 0;
        ra1 = 5'd0; ra2 = 5'd0;
        #1;
        check32(rd1, 32'h0, "R0 hardwired 0 (rd1)");
        check32(rd2, 32'h0, "R0 hardwired 0 (rd2)");

        // -------------------------------------------------------
        // TEST 2: Basic write then read
        // -------------------------------------------------------
        write_reg(5'd1, 32'hA5A5A5A5);
        ra1 = 5'd1;
        #1;
        check32(rd1, 32'hA5A5A5A5, "WRITE/READ r1 = 0xA5A5A5A5");

        // -------------------------------------------------------
        // TEST 3: Write multiple registers, read independently
        // -------------------------------------------------------
        write_reg(5'd2, 32'h12345678);
        write_reg(5'd3, 32'hCAFEBABE);
        ra1 = 5'd2; ra2 = 5'd3;
        #1;
        check32(rd1, 32'h12345678, "MULTI WRITE: rd1 = r2");
        check32(rd2, 32'hCAFEBABE, "MULTI WRITE: rd2 = r3");

        // -------------------------------------------------------
        // TEST 4: Overwrite a register with new value
        // -------------------------------------------------------
        write_reg(5'd1, 32'h00000001);
        ra1 = 5'd1;
        #1;
        check32(rd1, 32'h00000001, "OVERWRITE r1 = 1");

        // -------------------------------------------------------
        // TEST 5: Read two ports simultaneously from different regs
        // -------------------------------------------------------
        write_reg(5'd4, 32'hAAAAAAAA);
        write_reg(5'd5, 32'h55555555);
        ra1 = 5'd4; ra2 = 5'd5;
        #1;
        check32(rd1, 32'hAAAAAAAA, "DUAL READ: rd1 = r4");
        check32(rd2, 32'h55555555, "DUAL READ: rd2 = r5");

        // -------------------------------------------------------
        // TEST 6: Read same register on both ports
        // -------------------------------------------------------
        write_reg(5'd6, 32'hBEEFCAFE);
        ra1 = 5'd6; ra2 = 5'd6;
        #1;
        check32(rd1, 32'hBEEFCAFE, "SAME REG BOTH PORTS: rd1");
        check32(rd2, 32'hBEEFCAFE, "SAME REG BOTH PORTS: rd2");

        // -------------------------------------------------------
        // TEST 7: we3=0 does NOT write (value should be unchanged)
        // -------------------------------------------------------
        write_reg(5'd7, 32'h11111111);
        // attempt write with we3=0
        @(posedge clk); #1;
        wa3 = 5'd7; wd3 = 32'hFFFFFFFF; we3 = 0;
        @(negedge clk); #1;
        ra1 = 5'd7;
        #1;
        check32(rd1, 32'h11111111, "WE3=0: r7 unchanged");

        // -------------------------------------------------------
        // TEST 8: Write to highest register (r31)
        // -------------------------------------------------------
        write_reg(5'd31, 32'hDEADDEAD);
        ra1 = 5'd31;
        #1;
        check32(rd1, 32'hDEADDEAD, "WRITE/READ r31");

        // -------------------------------------------------------
        // TEST 9: Write zero explicitly to a register
        // -------------------------------------------------------
        write_reg(5'd8, 32'hFFFFFFFF);
        write_reg(5'd8, 32'h00000000);
        ra1 = 5'd8;
        #1;
        check32(rd1, 32'h00000000, "WRITE ZERO to r8");

        // -------------------------------------------------------
        // TEST 10: Reads are combinational — ra1/ra2 change
        //          reflects immediately without a clock edge
        // -------------------------------------------------------
        write_reg(5'd9,  32'h00000009);
        write_reg(5'd10, 32'h00000010);
        ra1 = 5'd9;
        #1;
        check32(rd1, 32'h00000009, "COMBINATIONAL READ: ra1=9");
        ra1 = 5'd10; // change read address without clock
        #1;
        check32(rd1, 32'h00000010, "COMBINATIONAL READ: ra1=10 (no clock)");

        $display("\n=== Results: %0d passed, %0d failed ===", pass, fail);
        $finish;
    end

endmodule
`endif // TB_REGFILE_SV