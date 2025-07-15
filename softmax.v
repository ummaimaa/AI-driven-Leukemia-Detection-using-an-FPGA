`timescale 1ns / 1ps

module Softmax #(
    parameter dataWidth = 16,        // Bit width of each input/output (Q2.14)
    parameter numInputs = 4         // Number of classes (outputs)
)(
    input clk,
    input rst,
    input [dataWidth*numInputs-1:0] in,   // Flattened input vector (64 bits)
    input in_valid,                       // Input valid signal from TopModule
    output reg [dataWidth*numInputs-1:0] out, // Flattened output vector
    output reg valid,                     // Output valid signal
    output reg [7:0] led_control          // LED control for Spartan 6
);

// Pipeline stages
localparam STAGE_IDLE = 2'b00,
           STAGE_EXP = 2'b01,
           STAGE_SUM = 2'b10,
           STAGE_NORM = 2'b11;
reg [1:0] state;
reg [dataWidth-1:0] input_array [0:numInputs-1];
reg [dataWidth-1:0] exp_values [0:numInputs-1]; // Q2.14 for exp
reg [dataWidth+2-1:0] sum_exp; // Q4.14 to handle sum of 4 terms
reg [dataWidth-1:0] softmax_output [0:numInputs-1];
reg [1:0] max_class;
reg [4:0] shift_amt; // Moved declaration here

// Lookup table for exponential (Q2.14, unchanged)
reg [dataWidth-1:0] exp_lut [0:15]; // Map input range [-2, 2) to e^x
initial begin
    exp_lut[0] = 16'h0800; // e^-2 ~ 0.135 (Q2.14: 0.135 * 2^14)
    exp_lut[1] = 16'h09D0; // e^-1.75
    exp_lut[2] = 16'h0C20; // e^-1.5
    exp_lut[3] = 16'h0F80; // e^-1.25
    exp_lut[4] = 16'h1480; // e^-1
    exp_lut[5] = 16'h1C80; // e^-0.75
    exp_lut[6] = 16'h2A00; // e^-0.5
    exp_lut[7] = 16'h4000; // e^-0.25
    exp_lut[8] = 16'h6800; // e^0 ~ 1
    exp_lut[9] = 16'hAC00; // e^0.25
    exp_lut[10] = 16'h1280; // e^0.5
    exp_lut[11] = 16'h1F80; // e^0.75
    exp_lut[12] = 16'h2C00; // e^1
    exp_lut[13] = 16'h4C00; // e^1.25
    exp_lut[14] = 16'h8000; // e^1.5
    exp_lut[15] = 16'hD800; // e^1.75
end

// Exponential approximation
function [dataWidth-1:0] exp_function;
    input [dataWidth-1:0] x;
    reg [3:0] lut_idx;
    begin
        // Map Q2.14 input [-2, 2) to LUT index [0, 15]
        lut_idx = x[7:4] + 4'd8; // Center around 0
        exp_function = exp_lut[lut_idx];
    end
endfunction

// Find shift amount for normalization (count leading zeros or estimate magnitude)
function [4:0] get_shift_amount;
    input [dataWidth+2-1:0] sum;
    reg [4:0] shift;
    begin
        shift = 0;
        if (sum[17:14] == 4'b0000) shift = 4; // sum < 1.0
        else if (sum[17:15] == 3'b001) shift = 3; // sum < 2.0
        else if (sum[17:16] == 2'b01) shift = 2; // sum < 4.0
        else if (sum[17] == 1'b1) shift = 1; // sum < 8.0
        else shift = 0; // sum >= 8.0
        get_shift_amount = shift;
    end
endfunction

// Pipeline control
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= STAGE_IDLE;
        out <= 0;
        valid <= 0;
        led_control <= 8'b0;
        sum_exp <= 0;
        max_class <= 0;
        shift_amt <= 0; // Initialize new register
        for (integer i = 0; i < numInputs; i = i + 1) begin
            input_array[i] <= 0;
            exp_values[i] <= 0;
            softmax_output[i] <= 0;
        end
    end else begin
        case (state)
            STAGE_IDLE: begin
                if (in_valid) begin
                    // Unpack input
                    input_array[0] <= in[15:0];
                    input_array[1] <= in[31:16];
                    input_array[2] <= in[47:32];
                    input_array[3] <= in[63:48];
                    state <= STAGE_EXP;
                end
            end
            STAGE_EXP: begin
                // Compute exponentials
                exp_values[0] <= exp_function(input_array[0]);
                exp_values[1] <= exp_function(input_array[1]);
                exp_values[2] <= exp_function(input_array[2]);
                exp_values[3] <= exp_function(input_array[3]);
                state <= STAGE_SUM;
            end
            STAGE_SUM: begin
                // Compute sum of exponentials
                sum_exp <= exp_values[0] + exp_values[1] + exp_values[2] + exp_values[3];
                state <= STAGE_NORM;
            end
            STAGE_NORM: begin
                // Normalize using shift-based approximation
                shift_amt <= get_shift_amount(sum_exp);

                softmax_output[0] <= exp_values[0] >> shift_amt;
                softmax_output[1] <= exp_values[1] >> shift_amt;
                softmax_output[2] <= exp_values[2] >> shift_amt;
                softmax_output[3] <= exp_values[3] >> shift_amt;

                // Pack output
                out <= {softmax_output[3], softmax_output[2], softmax_output[1], softmax_output[0]};

                // Find max class
                max_class <= 0;
                if (softmax_output[1] > softmax_output[0]) max_class <= 1;
                if (softmax_output[2] > softmax_output[max_class]) max_class <= 2;
                if (softmax_output[3] > softmax_output[max_class]) max_class <= 3;

                // LED control (updated to use LD0 to LD3)
                case (max_class)
                    2'b00: led_control <= 8'b00000001; // LD0 (U18, led_control[0])
                    2'b01: led_control <= 8'b00000010; // LD1 (M14, led_control[1])
                    2'b10: led_control <= 8'b00000100; // LD2 (L14, led_control[2])
                    2'b11: led_control <= 8'b00001000; // LD3 (N14, led_control[3])
                    default: led_control <= 8'b00000000;
                endcase

                valid <= 1;
                state <= STAGE_IDLE;
            end
        endcase
    end
end

endmodule