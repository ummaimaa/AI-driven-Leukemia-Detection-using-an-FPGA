`timescale 1ns / 1ps

module weight_memory #(
    parameter DEPTH = 1024,                   // Number of weights (matches NUM_INPUTS from neuron)
    parameter WIDTH = 16,                     // Data width (16-bit Q2.14)
    parameter LAYER_NUM = 0,                  // Layer number
    parameter NEURON_NUM = 0,                 // Neuron number within layer
    parameter ADDR_WIDTH = $clog2(DEPTH + 1), // Address width (derived from DEPTH, default 10 for DEPTH = 1024)
    parameter weightFile = "weights.mif",     // Path to preloaded weights file
    parameter biasFile = "biases.mif"         // Path to preloaded bias file
)(
    input wire clk,                          // Clock input
    input wire rst,                          // Reset input
    input wire write_enable,                 // Write enable
    input wire [ADDR_WIDTH-1:0] write_addr, // Write address
    input wire [WIDTH-1:0] write_data,       // Input weight data to write
    input wire [ADDR_WIDTH-1:0] read_addr,   // Read address
    output reg [WIDTH-1:0] read_data         // Output weight data
);

    // Derived parameter (redundant but kept for clarity)
    localparam BIAS_ADDR = DEPTH;             // Bias stored at address 1024

    // Memory array: weights and bias
    reg [WIDTH-1:0] mem [0:DEPTH];           // Memory for 1024 weights + 1 bias (addresses 0 to 1024)

    // If pretrained, load weights and bias from files
    `ifdef pretrained
        initial begin 
            // Load weights into mem[0:DEPTH-1]
            $readmemh(weightFile, mem, 0, DEPTH-1);
            // Load bias into mem[DEPTH]
            $readmemh(biasFile, mem, DEPTH, DEPTH);
        end
    `else 
        // Write logic for weights and bias
        always @(posedge clk) begin
            if (rst) begin
                // No memory reset (handled by FPGA block RAM initialization)
            end else if (write_enable && write_addr <= BIAS_ADDR) begin
                mem[write_addr] <= write_data; // Write weights (0 to 1023) or bias (1024)
            end
        end
    `endif 

    // Read logic
    always @(posedge clk) begin
        if (rst) begin
            read_data <= 0; // Reset output to prevent latches
        end else begin
            if (read_addr <= BIAS_ADDR) begin
                read_data <= mem[read_addr]; // Read weights (0 to 1023) or bias (1024)
            end else begin
                read_data <= 0; // Default for invalid addresses
            end
        end
    end

endmodule