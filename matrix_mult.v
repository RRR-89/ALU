`timescale 1ns / 1ps

module matrix_mult(
    input  clk,
    input  rst,       // synchronous reset (active high)
    input  start,     // start the multiplication operation
    input  signed [255:0] matrix_a, // Flattened 4x4 matrix A (16 elements x 16 bits)
    input  signed [255:0] matrix_b, // Flattened 4x4 matrix B (16 elements x 16 bits)
    output reg done,  // asserted when computation is complete
    output reg signed [255:0] matrix_c // Flattened 4x4 output matrix
);

    // Internal storage for matrix elements
    reg signed [15:0] A [0:15];
    reg signed [15:0] B [0:15];
    reg signed [15:0] C [0:15];

    // Index counters
    reg [1:0] row, col, k;
    
    // Accumulator (32-bit for proper fixed-point accumulation)
    reg signed [31:0] acc;

    // FSM state definition
    localparam IDLE = 2'b00,
               CALC = 2'b01,
               DONE = 2'b10;
    reg [1:0] state;

    // Integer for loop iterations
    integer i;

    //-------------------------------------------------------------------------------
    // Unpacking the flattened input matrices into internal registers at start
    //-------------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            // Reset internal registers and indices
            for (i = 0; i < 16; i = i+1) begin
                A[i] <= 0;
                B[i] <= 0;
                C[i] <= 0;
            end
            row  <= 0;
            col  <= 0;
            k    <= 0;
            acc  <= 0;
            done <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        // Load matrices into internal registers
                        for (i = 0; i < 16; i = i+1) begin
                            A[i] <= matrix_a[i*16 +: 16];
                            B[i] <= matrix_b[i*16 +: 16];
                        end
                        // Initialize indices
                        row  <= 0;
                        col  <= 0;
                        k    <= 0;
                        acc  <= 0;
                        state <= CALC;
                    end
                end

                CALC: begin
                    // Compute: C[row][col] += (A[row][k] * B[k][col]) >>> 8
                    if (k < 4) begin
                        acc <= acc + ((A[row*4 + k] * B[k*4 + col]) >>> 8);
                        k <= k + 1;
                    end 
                    if (k == 3) begin
                        // Store the computed element
                        C[row*4 + col] <= acc;
                        acc <= 0; // Reset accumulator
                        k <= 0;    // Reset inner loop
                        // Move to next element
                        if (col == 3) begin
                            col <= 0;
                            if (row == 3) begin
                                state <= DONE;
                            end else begin
                                row <= row + 1;
                            end
                        end else begin
                            col <= col + 1;
                        end
                    end
                end

                DONE: begin
                    done <= 1;
                end

                default: state <= IDLE;
            endcase
        end
    end
	   

    //-------------------------------------------------------------------------------
    // Packing computed matrix C into the output bus when computation is complete
    //-------------------------------------------------------------------------------
    always @(posedge clk) begin
        if (done) begin
            for (i = 0; i < 16; i = i+1) begin
                matrix_c[i*16 +: 16] <= C[i];
            end
				
        end
    end
	 
    


endmodule


