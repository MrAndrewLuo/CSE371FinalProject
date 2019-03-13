// with saturation clipping
module kernel_convolution
	#(parameter KERNEL_SIZE = 3)
	(
	input logic clk, reset,

	// rgb with 32 bits each (signed integer)
	input logic signed [47:0] buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0], 
		
	// assume 31 bit signed integer for channel
	// kernel dimensions are w x h x 3
	input logic signed [47:0] kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0] ,
		
	// output signed
	output logic signed [31:0] ans 
	);	
	
	// loading kernel
	logic signed [47:0] kernel [KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	logic signed [47:0] buffer[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	always_ff @(posedge clk) begin
		if (reset) begin
			kernel <= kernel_in;
			buffer <= buffer_in;
		end
	end
	
	// multiply and accumulate across rows and columns
	logic signed [31:0] sum
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	genvar row, col;
	generate
		for (row = 0; row < KERNEL_SIZE; row += 1) begin: gen_row1
			for (col = 0; col < KERNEL_SIZE; col += 1) begin: gen_col2
				logic signed [31:0] br, bg, bb;
				logic signed [31:0] kr, kg, kb;
				assign {br, bg, bb} = buffer[row][col];
				assign {kr, kg, kb} = kernel[row][col];
				
				assign sum[row][col] = br * kr + bg * kg + bb * kb;
			end
		end
	endgenerate
	
	logic signed [31:0] accumulator_col
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	generate
		for (row = 0; row < KERNEL_SIZE; row += 1) begin: gen_row2
			assign accumulator_col[row][0] = sum[row][0];
			for (col = 1; col < KERNEL_SIZE; col += 1) begin: gen_col2			
				assign accumulator_col[row][col] = accumulator_col[row][col - 1] + sum[row][col];
			end
		end
	endgenerate
	
	logic signed [31:0] accumulator_row [KERNEL_SIZE - 1:0];
	generate
		assign accumulator_row[0] = accumulator_col[0][KERNEL_SIZE - 1];
		for (row = 1; row < KERNEL_SIZE; row += 1) begin: gen_row3
			assign accumulator_row[row] = accumulator_row[row - 1] + accumulator_col[row][KERNEL_SIZE - 1];
		end
	endgenerate
	
	always_ff @(posedge clk) begin
		if (!reset) ans <= accumulator_row[KERNEL_SIZE - 1];
	end
	
endmodule

module kernel_convolution_test_bench ();
	localparam KERNEL_SIZE = 5;

	logic clk, reset;

	// rgb with 32 bits each (signed integer)
	logic signed [47:0] buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	
	// rgb for visualization
	logic signed [32:0] r_buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	logic signed [32:0] g_buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	logic signed [32:0] b_buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];	
	
	// assume 31 bit signed integer for channel
	// kernel dimensions are w x h x 3
	logic signed [47:0] kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
		
	// rgb for visualization
	logic signed [32:0] r_kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	logic signed [32:0] g_kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	logic signed [32:0] b_kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	
	// output signed
	logic signed [31:0] ans;
	
	kernel_convolution #(KERNEL_SIZE) dut (.*);
	
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
					reg signed [31:0] br, bg, bb, kr, kg, kb;
					assign br = i * j; 
					assign bg = i + j; 
					assign bb = j;
					assign kr = 1;
					assign kg = -1;
					assign kb = 2;
					
					assign buffer_in[i][j] = {br, bg, bb};
					assign kernel_in[i][j] = {kr, kg, kb};
					
					assign r_buffer_in[i][j] = br;
					assign g_buffer_in[i][j] = bg;
					assign b_buffer_in[i][j] = bb;

					assign r_kernel_in[i][j] = kr;
					assign g_kernel_in[i][j] = kg;
					assign b_kernel_in[i][j] = kb;
				end
		end
	endgenerate
	initial begin
		
		reset <= 1; @(posedge clk);
		reset <= 0; @(posedge clk); @(posedge clk);
				
		$stop;
	end //initial
endmodule



/*
module kernel_convolution_testbench();
	logic signed [47:0] buffer_in
	logic signed [31:0] ans
	//  signed
	logic clk, reset,
	logic signed [47:0] kernel_in

	// Set up the clock.
	parameter PERIOD = 100; // period = length of clock
	initial begin
		clk <= 0;
		forever #(PERIOD/2) clk = ~clk;
	end

	kernel_convolution dut (.*); // ".*" Implicitly connects all ports to variables with matching names

	initial begin

		repeat (10) @(posedge clk);
		$stop; // End simulation
	end
endmodule
*/