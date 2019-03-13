// with saturation clipping
module kernel_convolution
	#(
	parameter KERNEL_SIZE = 3,
	parameter WORD_SIZE = 16)
	(
	// rgb with (WORD_SIZE - 1) bits each (signed integer)
	input logic signed [WORD_SIZE- 1:0] buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0], 
		
	// assume (WORD_SIZE - 1) bit signed integer for channel
	// kernel dimensions are w x h x 3
	input logic signed [WORD_SIZE - 1:0] kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0] ,
		
	// output signed
	output logic signed [(WORD_SIZE - 1):0] ans 
	);	
	
	// multiply and accumulate across rows and columns
	logic signed [WORD_SIZE - 1:0] sum
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	genvar row, col;
	generate
		for (row = 0; row < KERNEL_SIZE; row += 1) begin: gen_row1
			for (col = 0; col < KERNEL_SIZE; col += 1) begin: gen_col2
				assign sum[row][col] = buffer_in[row][col] * kernel_in[row][col];
			end
		end
	endgenerate
	
	logic signed [(WORD_SIZE - 1):0] accumulator_col
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	generate
		for (row = 0; row < KERNEL_SIZE; row += 1) begin: gen_row2
			assign accumulator_col[row][0] = sum[row][0];
			for (col = 1; col < KERNEL_SIZE; col += 1) begin: gen_col2			
				assign accumulator_col[row][col] = accumulator_col[row][col - 1] + sum[row][col];
			end
		end
	endgenerate
	
	logic signed [(WORD_SIZE - 1):0] accumulator_row [KERNEL_SIZE - 1:0];
	generate
		assign accumulator_row[0] = accumulator_col[0][KERNEL_SIZE - 1];
		for (row = 1; row < KERNEL_SIZE; row += 1) begin: gen_row3
			assign accumulator_row[row] = accumulator_row[row - 1] + accumulator_col[row][KERNEL_SIZE - 1];
		end
	endgenerate
	
	assign ans = accumulator_row[KERNEL_SIZE - 1];
	
endmodule

module kernel_convolution_testbench ();
	localparam KERNEL_SIZE = 5;
	localparam WORD_SIZE = 8;

	logic clk;

	// rgb with (WORD_SIZE - 1) bits each (signed integer)
	logic signed [((WORD_SIZE * 3) - 1):0] buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	
	// rgb for visualization
	logic signed [(WORD_SIZE - 1):0] r_buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	logic signed [(WORD_SIZE - 1):0] g_buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	logic signed [(WORD_SIZE - 1):0] b_buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];	
	
	// assume (WORD_SIZE - 1) bit signed integer for channel
	// kernel dimensions are w x h x 3
	logic signed [((WORD_SIZE * 3) - 1):0] kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
		
	// rgb for visualization
	logic signed [(WORD_SIZE - 1):0] r_kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	logic signed [(WORD_SIZE - 1):0] g_kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	logic signed [(WORD_SIZE - 1):0] b_kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	
	// output signed
	logic signed [(WORD_SIZE - 1):0] ans;
	
	kernel_convolution #(KERNEL_SIZE, WORD_SIZE) dut (.*);
	
	// Set up the clock.
	parameter CLOCK_PERIOD=100;
	initial clk=1;
	always begin
		#(CLOCK_PERIOD/2);
		clk = ~clk;
	end
	
	genvar i, j; 
	generate
		for (i = 0; i < KERNEL_SIZE; i++) begin: genrow
				for (j = 0; j < KERNEL_SIZE; j++) begin: gencol
					reg signed [(WORD_SIZE - 1):0] br, bg, bb, kr, kg, kb;
					assign b = i * j; 
					assign k = 1;
					
					assign buffer_in[i][j] = b;
					assign kernel_in[i][j] = k;
				end
		end
	endgenerate
	initial begin
		
		@(posedge clk); @(posedge clk); @(posedge clk);
				
		$stop;
	end //initial
endmodule