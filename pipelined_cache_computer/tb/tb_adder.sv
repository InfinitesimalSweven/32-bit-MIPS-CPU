`timescale 1ns/1ps
`include "adder.sv"

module tb_adder;

  // Parameters
  parameter n = 32;

  // Signals
  logic [n-1:0] A, B;
  logic [n-1:0] Y;

  // Instantiate DUT
  adder #(n) dut (
    .A(A),
    .B(B),
    .Y(Y)
  );

  // Test procedure
  initial begin
    $dumpfile("tb_adder.vcd");
    $dumpvars(0, tb_adder);

    // Test 1
    A = 5; B = 3;
    #1;
    check(5, 3);

    // Test 2
    A = 10; B = 7;
    #1;
    check(10, 7);

    // Test 3 (edge case: zero)
    A = 0; B = 0;
    #1;
    check(0, 0);

    // Test 4 (overflow behavior)
    A = 32'hFFFFFFFF; B = 1;
    #1;
    check(32'hFFFFFFFF, 1);

    // Random tests
    repeat (10) begin
      A = $urandom;
      B = $urandom;
      #1;
      check(A, B);
    end

    $display("All tests completed");
    $finish;
  end

  // Checking task
  task check(input [n-1:0] a, input [n-1:0] b);
    logic [n-1:0] expected;
    expected = a + b;

    if (Y !== expected) begin
      $error("FAIL: A=%0d B=%0d | Y=%0d (expected %0d)", a, b, Y, expected);
    end else begin
      $display("PASS: A=%0d B=%0d | Y=%0d", a, b, Y);
    end
  endtask

endmodule