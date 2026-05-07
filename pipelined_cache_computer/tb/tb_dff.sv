`include "_timescale.sv"

module tb_dff;
    parameter N = 8;
    logic clk, reset;
    logic [N-1:0] D, Q;

    dff #(.n(N)) dut (.CLOCK(clk), .RESET(reset), .D(D), .Q(Q));

    initial clk = 0;
    always #5 clk = ~clk;

    task tick(input [N-1:0] d_in);
        D = d_in; @(posedge clk); #1;
    endtask

    initial begin
        $dumpfile("tb_dff.vcd"); $dumpvars(0, tb_dff);
        reset = 1; D = 0; @(posedge clk); #1;

        // TEST 1: reset holds Q=0
        if (Q === 8'h00) $display("PASS TEST 1: reset holds Q=0");
        else             $display("FAIL TEST 1: Q=%h", Q);

        reset = 0;

        // TEST 2: captures D on posedge
        tick(8'hA5);
        if (Q === 8'hA5) $display("PASS TEST 2: Q captured 0xA5");
        else             $display("FAIL TEST 2: Q=%h", Q);

        // TEST 3: holds value when D changes between edges
        D = 8'hFF; #2; // change D mid-cycle
        if (Q === 8'hA5) $display("PASS TEST 3: Q stable mid-cycle");
        else             $display("FAIL TEST 3: Q=%h", Q);

        // TEST 4: sync reset overrides D
        D = 8'h55; reset = 1; @(posedge clk); #1;
        if (Q === 8'h00) $display("PASS TEST 4: async reset clears Q");
        else             $display("FAIL TEST 4: Q=%h", Q);

        $display("Done."); $finish;
    end
endmodule