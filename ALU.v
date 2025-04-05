module fixed_point_alu (
    input clk,
    input rst,
    input [1:0] op,          // 00=add, 01=sub, 10=mul (Q8.8?Q16.8), 11=div
    input signed [15:0] a,   // Q8.8 input A
    input signed [15:0] b,   // Q8.8 input B
    output reg signed [23:0] out,  // Q16.8 output for mul, Q8.8 for others
    output reg overflow      // High on overflow
);

    // Q8.8 and Q16.8 range limits
    localparam Q8_MAX_POS = 16'sh7FFF;   // 127.99609375
    localparam Q8_MAX_NEG = 16'sh8000;   // -128.0
    localparam Q16_MAX_POS = 24'sh7FFFFF; // 32767.99609375
    localparam Q16_MAX_NEG = 24'sh800000; // -32768.0

    // Intermediate signals
    reg signed [31:0] mul_result;  // Q16.16 for multiplication
    reg signed [23:0] add_sub_result;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out <= 0;
            overflow <= 0;
        end else begin
            case (op)
                // Addition (Q8.8 + Q8.8 ? Q8.8)
                2'b00: begin
                    add_sub_result = a + b;
                    // Overflow check
                    if ((a > 0 && b > 0 && add_sub_result < 0) || 
                        (a < 0 && b < 0 && add_sub_result > 0)) begin
                        overflow <= 1;
                        out <= (a[15] == 1) ? Q16_MAX_NEG : Q16_MAX_POS;
                    end else begin
                        overflow <= 0;
                        out <= { {8{add_sub_result[15]}}, add_sub_result }; // Sign-extend to Q16.8
                    end
                end

                // Subtraction (Q8.8 - Q8.8 ? Q8.8)
                2'b01: begin
                    add_sub_result = a - b;
                    // Overflow check
                    if ((a > 0 && b < 0 && add_sub_result < 0) || 
                        (a < 0 && b > 0 && add_sub_result > 0)) begin
                        overflow <= 1;
                        out <= (a[15] == 1) ? Q16_MAX_NEG : Q16_MAX_POS;
                    end else begin
                        overflow <= 0;
                        out <= { {8{add_sub_result[15]}}, add_sub_result }; // Sign-extend
                    end
                end

                // Multiplication (Q8.8 × Q8.8 ? Q16.8)
               2'b10: begin
    mul_result = a * b;  // Q16.16 intermediate
    // Right-shift by 8 to get Q16.8 (24-bit)
    

    // Check for overflow with SIGNED comparisons
    if ($signed(mul_result[31:8]) > $signed(Q16_MAX_POS)) begin
        overflow <= 1;
        out <= Q16_MAX_POS;
    end else if ($signed(mul_result[31:8]) < $signed(Q16_MAX_NEG)) begin
        overflow <= 1;
        out <= Q16_MAX_NEG;
    end else begin
        overflow <= 0;
        out <= mul_result[31:8];  // Correct Q16.8 output
    end
end

                // Division (Q8.8 / Q8.8 ? Q8.8)
                2'b11: begin
                    if (b == 0) begin  // Division by zero
                        overflow <= 1;
                        out <= (a[15] == 1) ? Q16_MAX_NEG : Q16_MAX_POS;
                    end else begin
                        // Left-shift numerator by 8 for precision
                        out <= (a << 8) / b;
                        overflow <= 0;
                    end
                end

                default: begin
                    out <= 0;
                    overflow <= 0;
                end
            endcase
        end
    end

endmodule
