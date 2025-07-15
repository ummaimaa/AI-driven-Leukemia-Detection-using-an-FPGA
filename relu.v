module ReLU #(
    parameter dataWidth = 16,
    parameter weightIntWidth = 2  // Q2.14 format (2 integer bits)
) ( 
    input clk,
    input rst,                    // Added reset
    input [2*dataWidth-1:0] x,    // 32-bit input (e.g., Q6.26 for MAC)
    output reg [dataWidth-1:0] out // 16-bit output (Q2.14)
); 
 
always @(posedge clk) begin 
    if (rst) begin
        out <= 0;                 // Initialize on reset
    end else begin
        if ($signed(x) >= 0) begin 
            // Check for overflow (sign bit + 2 integer bits)
            if (|x[2*dataWidth-1-:weightIntWidth+1])  // x[31:29]
                out <= {1'b0, {(dataWidth-1){1'b1}}}; // Saturate to 16'h7FFF
            else 
                out <= x[2*dataWidth-1-weightIntWidth-:dataWidth]; // x[29:14]
        end 
        else  
            out <= 0;  // Negative input results in 0 
    end
end 
 
endmodule