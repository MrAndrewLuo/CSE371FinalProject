// with saturation clipping
module kernel_convolution
	#(
	parameter KERNEL_SIZE = 3,
	parameter WORD_SIZE = 16
	)
	(
	input logic clk,
	
	// rgb with (WORD_SIZE - 1) bits each (signed integer)
	input logic signed [WORD_SIZE- 1:0] buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0], 
		
	// assume (WORD_SIZE - 1) bit signed integer for channel
	// kernel dimensions are w x h x 3
	input logic signed [WORD_SIZE - 1:0] kernel_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0],
		
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
				quick_mult #(WORD_SIZE) qm(.clk, .in1(buffer_in[row][col]), .in2(kernel_in[row][col]), .out(sum[row][col]));
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
	
	logic signed [(WORD_SIZE - 1):0] accumulator_col_buffered
	[KERNEL_SIZE - 1:0];
	generate
		for (row = 0; row < KERNEL_SIZE; row += 1) begin: gen_col_buff
			always_ff @(posedge clk) accumulator_col_buffered[row] = accumulator_col[row][KERNEL_SIZE - 1];
		end
	endgenerate
	
	logic signed [(WORD_SIZE - 1):0] accumulator_row [KERNEL_SIZE - 1:0];
	generate
		assign accumulator_row[0] = accumulator_col_buffered[0];
		for (row = 1; row < KERNEL_SIZE; row += 1) begin: gen_row3
			assign accumulator_row[row] = accumulator_row[row - 1] + accumulator_col_buffered[row];
		end
	endgenerate
	
	assign ans = accumulator_row[KERNEL_SIZE - 1];
	
endmodule

// common multiplications which are ez and commonly used
module quick_mult 
#(parameter WORD_SIZE = 16)
(
input logic clk,
input logic signed [WORD_SIZE - 1:0] in1, in2, // assume |in1| <<< |in2|
output logic signed [WORD_SIZE - 1:0] out
);
logic signed [WORD_SIZE - 1:0] correct_sign_in1, correct_sign_in2;
logic signed [WORD_SIZE - 1:0] shifted;

always_comb begin
	if (in2 < 0) correct_sign_in1 = ~in1 + 1;
	else correct_sign_in1 = in1;
	
	if (in2 < 0) correct_sign_in2 = ~in2 + 1;
	else correct_sign_in2 = in2;
	
	case (correct_sign_in2)
		1: shifted = correct_sign_in1;
		2: shifted = correct_sign_in1 <<< 1;
		3: shifted = (correct_sign_in1 <<< 1) + correct_sign_in1;
		4: shifted = correct_sign_in1 <<< 2;
		5: shifted = (correct_sign_in1 <<< 2) + correct_sign_in1;
		6: shifted = (correct_sign_in1 <<< 2) + (correct_sign_in1 <<< 1);
		7: shifted = correct_sign_in1 <<< 3;
		8: shifted = correct_sign_in1 <<< 3;
		default: shifted = 0;
	endcase
end

always_ff @(posedge clk) begin
	out <= shifted;
end
endmodule

module quick_mul_testbench ();
	localparam WORD_SIZE = 16;
	
	logic clk;
	logic signed [WORD_SIZE - 1:0] in1, in2; // assume |in1| <<< |in2|
	logic signed [WORD_SIZE - 1:0] out;
	
	// Set up the clock.
	parameter CLOCK_PERIOD=100;
	initial clk=1;
	always begin
		#(CLOCK_PERIOD/2);
		clk = ~clk;
	end
	
	quick_mult #(WORD_SIZE) dut(.*);
	
	initial begin
		in1 <= 6; 
		in2 <= 1; @(posedge clk); 
		in2 <= 2; @(posedge clk); 
		in2 <= 4; @(posedge clk);
		in2 <= -1; @(posedge clk); 
		in2 <= -2; @(posedge clk); 
		in2 <= -4; @(posedge clk); 
		in2 <= 0; @(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		$stop;
	end //initial
endmodule

module kernel_convolution_testbench ();
	localparam KERNEL_SIZE = 5;
	localparam WORD_SIZE = 8;

	logic clk;

	logic signed [WORD_SIZE - 1:0] buffer_in
	[KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0];
	
	// assume (WORD_SIZE - 1) bit signed integer for channel
	// kernel dimensions are w x h x 3
	logic signed [WORD_SIZE- 1:0] kernel_in
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
					if (i != 0 | j != 0) begin
						assign buffer_in[i][j] = i * j;
					end
				end
		end
	endgenerate
	
	generate
		for (i = 0; i < KERNEL_SIZE; i++) begin: genrow2
			for (j = 0; j < KERNEL_SIZE; j++) begin: gencol2
				if (i == 0) assign kernel_in[i][j] = 1;
				else if (i == KERNEL_SIZE - 1) assign kernel_in[i][j] = -1;
				else assign kernel_in[i][j] = 0;
			end		
		end
	endgenerate
	
	integer k;
	initial begin
		for (k = 1; k < 100; k++) begin
			buffer_in[0][0] = k;
			@(posedge clk);
		end

		repeat (20) @(posedge clk);
		$stop;
	end //initial
endmodule