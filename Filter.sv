// Warning: the Terasic VGA controller appears to have a few off-by-one errors.  If your code is very 
// sensitive to the EXACT number of pixels per line, you may have issues.  You have been warned!

// Warning: the Terasic VGA controller appears to have a few off-by-one errors.  If your code is very 
// sensitive to the EXACT number of pixels per line, you may have issues.  You have been warned!

module Filter #(parameter WIDTH = 800, parameter HEIGHT = 480)
(
	input logic		          		VGA_CLK, // 25 MHz clock
 
	// *** Incoming VGA signals ***
	// Colors.  0 if iVGA_BLANK_N is false.  Higher numbers brighter
	input logic		     [7:0]		iVGA_B, // Blue
	input logic		     [7:0]		iVGA_G, // Green
	input logic		     [7:0]		iVGA_R, // Red
	// Horizontal sync.  Low between horizontal lines.
	input logic		          		iVGA_HS,
	// Vertical sync.  Low between video frames.
	input logic		          		iVGA_VS,
	// Always zero
	input logic		          		iVGA_SYNC_N,
	// True in area not shown, false during the actual image.
 	input logic		          		iVGA_BLANK_N,

	// *** Outgoing VGA signals ***
	output logic		  [7:0]		oVGA_B,
	output logic		  [7:0]		oVGA_G,
	output logic		  [7:0]		oVGA_R,
	output logic		       		oVGA_HS,
	output logic		       		oVGA_VS,
	output logic		       		oVGA_SYNC_N,
 	output logic		       		oVGA_BLANK_N,
	
	// *** Board outputs ***
	output logic		     [6:0]		HEX0,
	output logic		     [6:0]		HEX1,
	output logic		     [6:0]		HEX2,
	output logic		     [6:0]		HEX3,
	output logic		     [6:0]		HEX4,
	output logic		     [6:0]		HEX5,
	output logic		     [9:0]		LEDR,

	// *** User inputs ***
	input logic 		     [1:0]		KEY, // Key[2] reserved for reset, key[3] for auto-focus.
	input logic			     [7:0]		SW   // SW[9] reserved for auto-focus mode.
);
	localparam PRECISION = 12;

	// Simple graphics hack
	logic [27:0] delay [1:0];
	logic [27:0] prev_delay0;
	logic [7:0] grayscale, grayscale_buffered; 
	logic signed [PRECISION - 1:0] grayscale16;
	
	// simple processing to grayscale
	always_comb begin		 
		grayscale = prev_delay0[27:20] / 4 + prev_delay0[19:12] / 8 * 5  + prev_delay0[11:4] / 10;
	end
	always_ff @(posedge VGA_CLK) begin
		grayscale16 <= {8'b0, grayscale_buffered};
		grayscale_buffered <= grayscale;
	end
	
	// sliding window operators to obtain proper buffers
	logic signed [PRECISION - 1:0] buffer_3 [2:0][2:0];	
	logic signed [PRECISION - 1:0] buffer_3_buffered [2:0][2:0];	
	always_ff @(posedge VGA_CLK) buffer_3_buffered <= buffer_3;
	sliding_window #(3, WIDTH, PRECISION) kernel_in_3 (.reset(0), .clk(VGA_CLK), .pixel_in(grayscale16), .buffer(buffer_3));

	// convolutions
	// identity kernel
	logic signed [PRECISION - 1:0] identity_out;
	logic signed [7:0] identity_out_8_bit;
	round_to_8_bit #(PRECISION) identity_round (.in(identity_out), .out(identity_out_8_bit));
	stream_kernel_3 #(
		0, 0, 0,
		0, 1, 0,
		0, 0, 0,
		PRECISION, WIDTH
	) identity_kernel (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_buffered),
		.out(identity_out)
	);
	
	// horizontal edge
	logic signed [PRECISION - 1:0] horz_out;
	logic signed [7:0] horz_out_8_bit;
	round_to_8_bit #(PRECISION) horz_round (.in(horz_out), .out(horz_out_8_bit));
	// convolutions
	stream_kernel_3 #(
		1, 2, 1,
		0, 0, 0,
		-1, -2, -1,
		PRECISION, WIDTH
	) horz_kernel (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_buffered),
		.out(horz_out)
	);
	
	// vertical edge
	logic signed [PRECISION - 1:0] vert_out;
	logic signed [7:0] vert_out_8_bit;
	round_to_8_bit #(PRECISION) vert_round (.in(vert_out), .out(vert_out_8_bit));
	// convolutions
	stream_kernel_3 #(
		-1, 0, 1,
		-2, 0, 2,
		-1, 0, 1,
		PRECISION, WIDTH
	) vert_kernel (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_buffered),
		.out(vert_out)
	);
	
	logic [7:0] sobel_8_bit;
	sobel_operator #(15, 24) sobel (.clk(VGA_CLK), .vert_in(vert_out), .horz_in(horz_out), .out(sobel_8_bit));
	/*
module 
sobel_operator
#(parameter N = 15, parameter PRECISION = 24)
(
input logic clk,
input logic signed [PRECISION - 1:0] vert_in, 
input logic signed [PRECISION - 1:0] horz_in,
output logic [7:0] out 
);
	*/
	
	// Before and after delays, outputs
	always_ff @(posedge VGA_CLK) begin
		{oVGA_R, oVGA_G, oVGA_B, oVGA_HS, oVGA_VS, oVGA_SYNC_N, oVGA_BLANK_N} <= delay[1];
		prev_delay0 <= delay[0];
		delay[0] <= {iVGA_R, iVGA_G, iVGA_B, iVGA_HS, iVGA_VS, iVGA_SYNC_N, iVGA_BLANK_N};
	end
	
	always_ff @(posedge VGA_CLK) begin		
		delay[1][3:0] <= delay[0][3:0];
		if (SW[0]) delay[1][27:4] <= {3{grayscale_buffered}};
		else if (SW[1]) delay[1][27:4] <= {3{identity_out_8_bit}};
		else if (SW[2]) delay[1][27:4] <= {3{horz_out_8_bit}};
		else if (SW[3]) delay[1][27:4] <= {3{vert_out_8_bit}};
		else if (SW[4]) delay[1][27:4] <= {3{sobel_8_bit}};
		else begin
			delay[1][27:4] <= delay[0][27:4];
		end

		//else if (SW[2]) delay[1][27:4] <= {vert_edge_out_buffered[7:0], vert_edge_out_buffered[7:0], vert_edge_out_buffered[7:0]};
		//else if (SW[3]) delay[1][27:4] <= {horz_edge_out_buffered[7:0], horz_edge_out_buffered[7:0], horz_edge_out_buffered[7:0]};
		//else if (SW[4]) delay[1][27:4] <= {sobel_out_buffered, sobel_out_buffered, sobel_out_buffered};
	end


	assign HEX0 = '1;
	assign HEX1 = '1;
	assign HEX2 = '1;
	assign HEX3 = '1;
	assign HEX4 = '1;
	assign HEX5 = '1;
	assign LEDR = '0;
endmodule


module round_to_8_bit #(parameter PRECISION = 16) 
(
input logic signed [PRECISION - 1:0] in,
output logic [7:0] out
);
always_comb begin
	if (in > 255)  out = 255; 
	else if (in < -255)  out = 255;
	else if (in < 0) out = ~in + 1;
	else out = in;
	end
endmodule


module Filter_testbench();
	logic		  [7:0]		oVGA_G;
	logic		       		oVGA_HS;
	logic		     [6:0]		HEX2;
	logic		     [7:0]		iVGA_G; // Green
	logic		       		oVGA_BLANK_N;
	logic		  [7:0]		oVGA_B;
	logic		          		iVGA_HS;
	logic		  [7:0]		oVGA_R;
	logic		     [6:0]		HEX3;
	logic		     [7:0]		iVGA_R; // Red
	logic		     [6:0]		HEX1;
	logic		     [6:0]		HEX0;
	logic		       		oVGA_VS;
	logic		       		oVGA_SYNC_N;
	logic			     [8:0]		SW;   // SW[9] reserved for auto-focus mode.
	logic		          		iVGA_SYNC_N;
	logic		          		VGA_CLK; // 25 MHz clock
	logic		          		iVGA_BLANK_N;
	logic		     [7:0]		iVGA_B; // Blue
	logic		     [9:0]		LEDR;
	logic		          		iVGA_VS;
	logic		     [6:0]		HEX4;
	logic clk;
	// *** User s ***
	// *** Board s ***
	logic		     [6:0]		HEX5;
	logic 		     [1:0]		KEY; // Key[2] reserved for reset, key[3] for auto-focus.

	// Set up the clock.
	parameter PERIOD = 40; // period = length of clock
	initial begin
		clk = 0;
		forever #(PERIOD/2) clk = ~clk;
	end

	Filter dut (.*); // ".*" Implicitly connects all ports to variables with matching names

	assign VGA_CLK = clk;
	
	integer i;
	initial begin
		iVGA_VS <= 0; iVGA_BLANK_N <= 0; iVGA_SYNC_N <= 0; iVGA_R <= 100; iVGA_G <= 100; iVGA_B <=100;

		for(i = 0; i < 200; i++) @(posedge clk);
		$stop; // End simulation
	end
endmodule

