module sliding_window 
#(parameter KERNEL_SIZE = 3, ROW_WIDTH= 100) 
(
input logic clk, reset,
input logic [7:0] pixel_in,
output logic [7:0] buffer [KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0]
);

	logic [8 * (KERNEL_SIZE - 1) - 1:0] 
		pass_by_buffer[ROW_WIDTH - KERNEL_SIZE:0];

	logic [$clog2(8 * (KERNEL_SIZE - 1)) - 1:0] counter;
		
	genvar row, col;
	
	// reset logic
	generate
		for (row = 0; row < KERNEL_SIZE; row += 1) begin: clear_buffer1
			for (col = 0; col < KERNEL_SIZE; col += 1) begin: clear_buffer2
				always_ff @(posedge clk) 
					if(reset) begin 
						buffer[row][col] <= 0; 
					end
					else begin
						if (row == KERNEL_SIZE - 1 && col == KERNEL_SIZE - 1) 
							buffer[row][col] <= pixel_in;
						else if (col == KERNEL_SIZE - 1) 
							buffer[row][col] <= pass_by_buffer[counter][(row + 1) * 8 - 1:(row) * 8];
						else
							buffer[row][col] <= buffer[row][col + 1];
					end
			end
		end
	endgenerate
	
	generate
		for (row = 0; row <= ROW_WIDTH - KERNEL_SIZE; row += 1) begin: clear_pass_by_buffers
			always_ff @(posedge clk) 
				if(reset) begin pass_by_buffer[row] <= 0; end
				else begin
					// TODO: fix pass in bufferes
					pass_by_buffer[row] <= 2;
				end
		end
	endgenerate
endmodule