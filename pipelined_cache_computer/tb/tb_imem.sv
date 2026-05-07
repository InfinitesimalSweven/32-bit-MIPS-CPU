`include "_timescale.sv"

module tb_imem;
    parameter R = 4; // small memory for test
    logic [R-1:0] addr;
    logic [31:0]  readdata;

    imem #(.n(32), .r(R)) dut (.addr(addr), .readdata(readdata));

    // Write a tiny hex file so imem has known contents
    initial begin
        $writememh("tb_imem_prog.exe", '{
            32'hDEADBEEF, 32'h12345678, 32'hCAFEBABE, 32'h00000001,
            32'h00000002, 32'h00000003, 32'h00000004, 32'h00000005,
            32'h00000006, 32'h00000007, 32'h00000008, 32'h00000009,
            32'h0000000A, 32'h0000000B, 32'h0000000C, 32'h0000000D
        });
    end

    initial begin
        $dumpfile("tb_imem.vcd"); $dumpvars(0, tb_imem);
        #1; // let $readmemh settle

        // TEST 1: addr 0
        addr = 0; #1;
        if (readdata === 32'hDEADBEEF) $display("PASS TEST 1: addr=0 readdata=%h", readdata);
        else                           $display("FAIL TEST 1: readdata=%h", readdata);

        // TEST 2: addr 1
        addr = 1; #1;
        if (readdata === 32'h12345678) $display("PASS TEST 2: addr=1 readdata=%h", readdata);
        else                           $display("FAIL TEST 2: readdata=%h", readdata);

        // TEST 3: addr 2
        addr = 2; #1;
        if (readdata === 32'hCAFEBABE) $display("PASS TEST 3: addr=2 readdata=%h", readdata);
        else                           $display("FAIL TEST 3: readdata=%h", readdata);

        // TEST 4: combinational — addr changes immediately update readdata
        addr = 3; #1;
        if (readdata === 32'h00000001) $display("PASS TEST 4: combinational read works");
        else                           $display("FAIL TEST 4: readdata=%h", readdata);

        $display("Done."); $finish;
    end
endmodule