// Include the include.v file
`include "include.v"

module TopModule #(
    parameter DATA_WIDTH = 16,
    parameter NUM_INPUTS = 1024,
    parameter NUM_HIDDEN = 1024,
    parameter NUM_OUTPUTS = 4
)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] myinput,
    input myinputValid,
    output [DATA_WIDTH*NUM_OUTPUTS-1:0] softmax_out,
    output softmax_valid,
    output [7:0] led_control // Added LED control output
);

    // Internal signals for hidden layer
    wire [DATA_WIDTH-1:0] hidden_outputs [0:NUM_HIDDEN-1];
    wire hidden_valid [0:NUM_HIDDEN-1];
    
    // Registers to store hidden layer outputs
    reg [DATA_WIDTH-1:0] hidden_results [0:NUM_HIDDEN-1];
    
    // Output layer signals
    wire [DATA_WIDTH-1:0] output_layer_outputs [0:NUM_OUTPUTS-1];
    wire output_layer_valid [0:NUM_OUTPUTS-1];
    wire [DATA_WIDTH*NUM_OUTPUTS-1:0] flat_output_layer_outputs;
    
    // State machine definitions
    localparam STATE_IDLE = 3'b000,
               STATE_COLLECT_HIDDEN = 3'b001,
               STATE_FEED_OUTPUT = 3'b010,
               STATE_WAIT_OUTPUT = 3'b011,
               STATE_FINAL = 3'b100,
               STATE_WAIT_SOFTMAX = 3'b101;  // New state to wait for softmax
    
    reg [2:0] current_state;
    reg [$clog2(NUM_HIDDEN)-1:0] hidden_count;
    reg [$clog2(NUM_INPUTS)-1:0] input_count;
    reg [$clog2(NUM_OUTPUTS)-1:0] output_count;
    
    // Signals for second layer feeding
    reg [DATA_WIDTH-1:0] current_input_to_output;
    reg current_input_valid;
    reg all_outputs_valid;
    
    // State machine for neural network control
    always @(posedge clk) begin
        if (rst) begin
            current_state <= STATE_IDLE;
            hidden_count <= 0;
            input_count <= 0;
            output_count <= 0;
            current_input_valid <= 0;
            all_outputs_valid <= 0;
        end else begin
            case (current_state)
                STATE_IDLE: begin
                    // Reset counters and control signals
                    hidden_count <= 0;
                    input_count <= 0;
                    output_count <= 0;
                    current_input_valid <= 0;
                    all_outputs_valid <= 0;
                    
                    // Move to collecting hidden layer outputs when data is valid
                    if (hidden_valid[0]) begin
                        current_state <= STATE_COLLECT_HIDDEN;
                    end
                end
                
                STATE_COLLECT_HIDDEN: begin
                    // Store outputs from hidden layer neurons
                    if (hidden_valid[hidden_count]) begin
                        hidden_results[hidden_count] <= hidden_outputs[hidden_count];
                        hidden_count <= hidden_count + 1;
                        
                        // Once all hidden outputs collected, prepare to feed output layer
                        if (hidden_count == NUM_HIDDEN-1) begin
                            current_state <= STATE_FEED_OUTPUT;
                            input_count <= 0;
                            output_count <= 0;
                        end
                    end
                end
                
                STATE_FEED_OUTPUT: begin
                    // Feed hidden layer outputs sequentially to all output neurons
                    if (input_count < NUM_HIDDEN) begin
                        current_input_to_output <= hidden_results[input_count];
                        current_input_valid <= 1;
                        input_count <= input_count + 1;
                    end else begin
                        current_input_valid <= 0;
                        current_state <= STATE_WAIT_OUTPUT;
                    end
                end
                
                STATE_WAIT_OUTPUT: begin
                    // Wait for all output neurons to complete
                    if (output_layer_valid[output_count]) begin
                        output_count <= output_count + 1;
                        
                        // Check if all outputs are ready
                        if (output_count == NUM_OUTPUTS-1) begin
                            all_outputs_valid <= 1;
                            current_state <= STATE_FINAL;
                        end
                    end
                end
                
                STATE_FINAL: begin
                    // Signal inputs are valid for softmax, then wait for completion
                    all_outputs_valid <= 0;
                    current_state <= STATE_WAIT_SOFTMAX;
                end
                
                STATE_WAIT_SOFTMAX: begin
                    // Wait for softmax computation to complete
                    if (softmax_valid) begin
                        current_state <= STATE_IDLE;
                    end
                end
            endcase
        end
    end

    // Hidden layer neurons - each receiving the same scalar input
    genvar i;
    generate
        for (i = 0; i < NUM_HIDDEN; i = i + 1) begin : hidden_layer
            neuron #(
                .LAYER_NUM(1),
                .NEURON_NUM(i),
                .NUM_INPUTS(NUM_INPUTS),
                .DATA_WIDTH(DATA_WIDTH),
                .ACTIVATION_TYPE(1), // ReLU activation
                .weightFile("dense_4_weights_int16.mif"),
                .biasFile("dense_4_biases_int16.mif")
            ) neuron_hidden (
                .clk(clk),
                .rst(rst),
                .data_in(myinput),
                .data_in_valid(myinputValid),
                .weight_valid(1'b0),
                .bias_valid(1'b0),
                .weight_in(16'd0),
                .bias_in(16'd0),
                .config_layer(1),
                .config_neuron(i),
                .neuron_out(hidden_outputs[i]),
                .neuron_out_valid(hidden_valid[i]),
                .overflow_flag() // Left unconnected for now
            );
        end
    endgenerate

    // Output layer neurons - each receiving the same sequence of inputs
    generate
        for (i = 0; i < NUM_OUTPUTS; i = i + 1) begin : output_layer
            neuron #(
                .LAYER_NUM(2),
                .NEURON_NUM(i),
                .NUM_INPUTS(NUM_HIDDEN),
                .DATA_WIDTH(DATA_WIDTH),
                .ACTIVATION_TYPE(0), // No activation for output layer
                .weightFile("dense_5_weights_int16.mif"),
                .biasFile("dense_5_biases_int16.mif")
            ) neuron_output (
                .clk(clk),
                .rst(rst),
                .data_in(current_input_to_output),
                .data_in_valid(current_input_valid),
                .weight_valid(1'b0),
                .bias_valid(1'b0),
                .weight_in(16'd0),
                .bias_in(16'd0),
                .config_layer(2),
                .config_neuron(i),
                .neuron_out(output_layer_outputs[i]),
                .neuron_out_valid(output_layer_valid[i]),
                .overflow_flag() // Left unconnected for now
            );
        end
    endgenerate

    // Flatten output layer outputs for softmax
    generate
        for (i = 0; i < NUM_OUTPUTS; i = i + 1) begin : flatten_output
            assign flat_output_layer_outputs[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH] = output_layer_outputs[i];
        end
    endgenerate

    // Softmax module instantiation
    Softmax #(
        .dataWidth(DATA_WIDTH),
        .numInputs(NUM_OUTPUTS)
    ) softmax_inst (
        .clk(clk),
        .rst(rst),
        .in(flat_output_layer_outputs),
        .in_valid(all_outputs_valid),
        .out(softmax_out),
        .valid(softmax_valid),
        .led_control(led_control) // Connect to top-level led_control output
    );
endmodule