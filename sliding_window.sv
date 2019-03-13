module sliding_window 
#(parameter KERNEL_SIZE = 3, ROW_WIDTH=640, WORD_SIZE = 8) 
(
input logic clk, reset,
input logic signed [WORD_SIZE - 1:0] pixel_in,
output logic signed [WORD_SIZE - 1:0] buffer [KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0]
);

	logic [WORD_SIZE * (KERNEL_SIZE - 1) - 1:0] 
		pass_by_buffer[ROW_WIDTH - KERNEL_SIZE - 1:0];

	logic [$clog2(WORD_SIZE * (KERNEL_SIZE - 1)) - 1:0] counter;
		
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
						else if (col == KERNEL_SIZE - 1 && row != KERNEL_SIZE - 1) 
							buffer[row][col] <= pass_by_buffer[counter][(row + 1) * WORD_SIZE - 1:(row) * WORD_SIZE];
						else
							buffer[row][col] <= buffer[row][col + 1];
					end
			end
		end
	endgenerate
	
	genvar row_gen, counter_gen;
	generate
		for (row_gen = 1; row_gen < KERNEL_SIZE; row_gen += 1) begin: pass_by_buffers_row
			always_ff @(posedge clk) begin
				if (!reset) pass_by_buffer[counter][(row_gen) * WORD_SIZE - 1:(row_gen - 1) * WORD_SIZE] <= buffer[row_gen][0];
			end
		end
	endgenerate
	
	always_ff @(posedge clk) begin
		if (reset) counter <= 0;
		else begin
			if(counter < ROW_WIDTH - KERNEL_SIZE - 1) counter <= counter + 1;
			else counter <= 0;
		end
	end
endmodule

module sliding_window_testbench
#(
parameter KERNEL_SIZE = 3,
parameter ROW_SIZE = 5,
parameter VALUES = 25,
parameter WORD_SIZE = 8
)
();
	// inputs
	logic clk, reset;
	logic signed [WORD_SIZE - 1:0] pixel_in;
	
	// output
	logic signed [WORD_SIZE - 1:0] buffer [KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	
	
	sliding_window #(KERNEL_SIZE, ROW_SIZE) dut (.*);
	
	// Set up the clock.
	parameter CLOCK_PERIOD=100;
	initial clk=1;
	always begin
		#(CLOCK_PERIOD/2);
		clk = ~clk;
	end
	
	integer i;
	initial begin
		
		reset <= 1; @(posedge clk);
		reset <= 0; 
		
		for (i = 1; i <= VALUES; i++) begin
			pixel_in <= i;
			@(posedge clk);
		end
		@(posedge clk);
		
		$stop;
	end //initial
endmodule

module sliding_window_testbench_runner();
	sliding_window_testbench #(3, 5, 100, 8) s1();
	sliding_window_testbench #(3, 10, 100, 8) s2();
	sliding_window_testbench #(5, 10, 100, 8) s3();

endmodule