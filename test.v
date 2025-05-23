`timescale 1ns / 1ps

module fixed_point_alu_tb();

    // Parameters
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz clock

    // Signals
    reg clk;
    reg rst;
    reg [1:0] op;
    reg signed [15:0] a;
    reg signed [15:0] b;
    wire signed [23:0] out;
    wire overflow;

    // Instantiate ALU
    fixed_point_alu uut (
        .clk(clk),
        .rst(rst),
        .op(op),
        .a(a),
        .b(b),
        .out(out),
        .overflow(overflow)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test procedure
    initial begin
        // Initialize
        rst = 1;
        op = 0;
        a = 0;
        b = 0;
        #20;
        rst = 0;

        // Test cases
        $display("Starting ALU tests...");
        $display("---------------------");

        // --------------------------
        // Addition Tests (op = 00)
        // --------------------------
        $display("\nTesting Addition:");
        op = 2'b00;
        
        // Test 1: 1.0 + 2.0 = 3.0
        a = 16'h0100;  // 1.0
        b = 16'h0200;  // 2.0
        #20;
        $display("%f + %f = %f (Expected: 3.0)", 
                $itor(a)/256.0, $itor(b)/256.0, $itor(out)/256.0);

        // Test 2: Overflow case (127 + 1 = 128 ? should saturate to 127.996)
        a = 16'h7F00;  // 127.0
        b = 16'h0100;  // 1.0
        #20;
        $display("%f + %f = %f (Overflow: %b, Expected: 127.996)", 
                $itor(a)/256.0, $itor(b)/256.0, $itor(out)/256.0, overflow);

        // --------------------------
        // Subtraction Tests (op = 01)
        // --------------------------
        $display("\nTesting Subtraction:");
        op = 2'b01;
        
        // Test 1: 5.0 - 2.0 = 3.0
        a = 16'h05f0;  // 5.0
        b = 16'h02d0;  // 2.0
        #20;
        $display("%f - %f = %f (Expected: 3.0)", 
                $itor(a)/256.0, $itor(b)/256.0, $itor(out)/256.0);

        // Test 2: Underflow case (-128 - 1 ? should saturate to -128)
        a = 16'h8000;  // -128.0
        b = 16'h0100;  // 1.0
        #20;
        $display("%f - %f = %f (Overflow: %b, Expected: -128.0)", 
                $itor(a)/256.0, $itor(b)/256.0, $itor(out)/256.0, overflow);

        // --------------------------
        // Multiplication Tests (op = 10)
        // --------------------------
        $display("\nTesting Multiplication:");
        op = 2'b10;
        
        // Test 1: 1.5 * 2.0 = 3.0 (Q8.8 ? Q16.8)
        a = 16'h01f0;  // 1.5
        b = 16'h0200;  // 2.0
        #20;
        $display("%f * %f = %f (Expected: 3.0)", 
                $itor(a)/256.0, $itor(b)/256.0, $itor(out)/256.0);

        // Test 2: 127 * 127 = 16129 (Q16.8 output)
        a = 16'h7F00;  // 127.0
        b = 16'h7F00;  // 127.0
        #20;
        $display("%f * %f = %f (Expected: 16129.0)", 
                $itor(a)/256.0, $itor(b)/256.0, $itor(out)/256.0);

        // --------------------------
        // Division Tests (op = 11)
        // --------------------------
        $display("\nTesting Division:");
        op = 2'b11;
        
        // Test 1: 8.0 / 2.0 = 4.0
        a = 16'h08f0;  // 8.0
        b = 16'h0281;  // 2.0
        #20;
        $display("%f / %f = %f (Expected: 4.0)", 
                $itor(a)/256.0, $itor(b)/256.0, $itor(out)/256.0);

        // Test 2: Division by zero
        a = 16'h0100;  // 1.0
        b = 16'h0000;  // 0.0
        #20;
        $display("%f / %f = %f (Overflow: %b, Expected: saturate)", 
                $itor(a)/256.0, $itor(b)/256.0, $itor(out)/256.0, overflow);

        // Finish simulation
        #100;
        $display("\nAll tests completed!");
        $finish;
    end

    // Monitor for waveform viewing
    initial begin
        $monitor("Time = %t: op = %b, a = %h, b = %h, out = %h, overflow = %b",
                 $time, op, a, b, out, overflow);
    end

endmodule
