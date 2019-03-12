module sliding_window 
#(parameter KERNEL_SIZE = 3, ROW_WIDTH=640) 
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
		for (row = 0; row < KERNEL_SIZE; row += 1) begin: main_buffer_row
			for (col = 0; col < KERNEL_SIZE; col += 1) begin: main_buffer_col
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
	
	genvar counter_gen, row_gen;
	generate
		for (counter_gen = 0; counter_gen <= ROW_WIDTH - KERNEL_SIZE; counter_gen += 1) begin: pass_by_buffers_entries
			for (row_gen = 1; row_gen < KERNEL_SIZE - 1; row_gen += 1) begin: pass_by_buffers_row
				always_ff @(posedge clk) 
					if(reset) begin pass_by_buffer[counter_gen] <= 0; end
					else begin
							pass_by_buffer[counter_gen][(row_gen) * 8 - 1:(row_gen - 1) * 8] <= buffer[row_gen][0];
					end
			end
		end
	endgenerate
	
	always_ff @(posedge clk) begin
		if (reset) counter <= 0;
		else begin
			if(counter < ROW_WIDTH - KERNEL_SIZE) counter <= counter + 1;
			else counter <= 0;
		end
	end
endmodule