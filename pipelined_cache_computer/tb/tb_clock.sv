`include "_timescale.sv"

module tb_clock;
    // Parameters
    parameter TICKS = 10;

    // DUT signals
    reg  ENABLE;
    wire CLOCK;

    // Instantiate DUT
    clock #(.ticks(TICKS)) dut (
        .ENABLE(ENABLE),
        .CLOCK(CLOCK)
    );

    integer i;
    real    half = TICKS / 2.0;

    task wait_cycles(input integer n);
        repeat (n) @(posedge CLOCK);
    endtask

    initial begin
        $dumpfile("tb_clock.vcd");
        $dumpvars(0, tb_clock);

        ENABLE = 0;
        #(TICKS * 2);

        // TEST 1: Clock should stay low while ENABLE = 0
        $display("[%0t] TEST 1: ENABLE=0, clock should stay low", $time);
        #(TICKS * 3);
        if (CLOCK !== 0)
            $display("FAIL TEST 1: CLOCK = %b, expected 0", CLOCK);
        else
            $display("PASS TEST 1: CLOCK held low while disabled");

        // TEST 2: Clock should toggle when ENABLE = 1
        $display("[%0t] TEST 2: Assert ENABLE, check toggling", $time);
        ENABLE = 1;
        #(half);
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge CLOCK);
            $display("[%0t] posedge %0d detected", $time, i);
        end
        $display("PASS TEST 2: Clock toggling with ENABLE=1");

        // TEST 3: Period check
        $display("[%0t] TEST 3: Period check", $time);
        begin
            real t0, t1, measured;
            @(posedge CLOCK); t0 = $realtime;
            @(posedge CLOCK); t1 = $realtime;
            measured = t1 - t0;
            if (measured != TICKS)
                $display("FAIL TEST 3: period = %0f, expected %0d", measured, TICKS);
            else
                $display("PASS TEST 3: period = %0f ns", measured);
        end

        // TEST 4: Disable mid-run, clock should go low
        $display("[%0t] TEST 4: Deassert ENABLE mid-run", $time);
        wait_cycles(3);
        ENABLE = 0;
        #(TICKS * 3);
        if (CLOCK !== 0)
            $display("FAIL TEST 4: CLOCK = %b after disable, expected 0", CLOCK);
        else
            $display("PASS TEST 4: CLOCK went low after ENABLE=0");

        // TEST 5: Re-enable after stop
        $display("[%0t] TEST 5: Re-enable after stop", $time);
        ENABLE = 1;
        @(posedge CLOCK);
        $display("PASS TEST 5: Clock restarted after re-enable");

        #(TICKS * 4);
        $display("[%0t] All tests done.", $time);
        $finish;
    end

    // Timeout watchdog
    initial begin
        #10000;
        $display("TIMEOUT: simulation exceeded limit");
        $finish;
    end

endmodule