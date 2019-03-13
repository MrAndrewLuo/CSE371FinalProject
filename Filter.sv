// Warning: the Terasic VGA controller appears to have a few off-by-one errors.  If your code is very 
// sensitive to the EXACT number of pixels per line, you may have issues.  You have been warned!

module Filter #(parameter WIDTH = 640, parameter HEIGHT = 480)
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
	input logic			     [8:0]		SW   // SW[9] reserved for auto-focus mode.
);
	localparam PRECISION_BITS = 16;
	localparam SCREEN_DELAY = 1;
	
/*
	module sliding_window 
#(parameter KERNEL_SIZE = 3, ROW_WIDTH=640, WORD_SIZE = 8) 
(
input logic clk, reset,
input logic signed [WORD_SIZE - 1:0] pixel_in,
output logic signed [WORD_SIZE - 1:0] buffer [KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0]
);*/

	// Simple graphics hack
	logic [27:0] VGA_BUFFER;
	logic [27:0] VGA_OUT;	
	
	// Before and after delays.
	always_ff @(posedge VGA_CLK) begin
		{oVGA_R, oVGA_G, oVGA_B, oVGA_HS, oVGA_VS, oVGA_SYNC_N, oVGA_BLANK_N} <= VGA_OUT;
		VGA_BUFFER <= {iVGA_R, iVGA_G, iVGA_B, iVGA_HS, iVGA_VS, iVGA_SYNC_N, iVGA_BLANK_N};
	end
	
	// grayscale
	logic signed [PRECISION_BITS - 1:0] grayscale16;
	logic [7:0] grayscale;
	always_ff @(posedge VGA_CLK) begin
		grayscale16 = VGA_OUT[27:20] / 4 + VGA_OUT[19:12] / 8 * 5  + VGA_OUT[11:4] / 10;
		grayscale = grayscale16[7:0];
	end
	
	logic signed [15:0] buffer_3 [2:0][2:0];
	logic signed [15:0] identity_kernel [2:0][2:0];
	logic signed [15:0] identity_out;
	
	// sliding window operators
	sliding_window #(3, 640, 16) kernel_in_3 (.clk(VGA_CLK), .pixel_in(grayscale16), .buffer(buffer_3));
	kernel_convolution #(3, 16) identity_convolve(.buffer_in(buffer_3), .kernel_in(identity_kernel), .ans(identity_out));
	
	always_ff @(posedge VGA_CLK) begin
		VGA_OUT <= VGA_BUFFER;
		if (SW[0]) VGA_OUT[27:4] = {grayscale, grayscale, grayscale};
		if (SW[1]) VGA_OUT[27:4] = {identity_out[7:0], identity_out[7:0], identity_out[7:0]};
	end
	
	// set HEXES later
	assign HEX0 = '1;
	assign HEX1 = '1;
	assign HEX2 = '1;
	assign HEX3 = '1;
	assign HEX4 = '1;
	assign HEX5 = '1;
	assign LEDR = '0;
endmodule



/*
module Filter_testbench();
	logic		  [7:0]		oVGA_G,
	logic		       		oVGA_HS,
	logic		     [6:0]		HEX2,
	logic		     [7:0]		iVGA_G, // Green
	logic		       		oVGA_BLANK_N,
	logic		  [7:0]		oVGA_B,
	logic		          		iVGA_HS,
	logic		  [7:0]		oVGA_R,
	logic		     [6:0]		HEX3,
	logic		     [7:0]		iVGA_R, // Red
	logic		     [6:0]		HEX1,
	logic		     [6:0]		HEX0,
	logic		       		oVGA_VS,
	logic		       		oVGA_SYNC_N,
	logic			     [8:0]		SW   // SW[9] reserved for auto-focus mode.
	logic		          		iVGA_SYNC_N,
	logic		          		VGA_CLK, // 25 MHz clock
	logic		          		iVGA_BLANK_N,
	logic		     [7:0]		iVGA_B, // Blue
	logic		     [9:0]		LEDR,
	logic		          		iVGA_VS,
	logic		     [6:0]		HEX4,
	// *** User s ***
	// *** Board s ***
	logic		     [6:0]		HEX5,
	logic 		     [1:0]		KEY, // Key[2] reserved for reset, key[3] for auto-focus.

	// Set up the clock.
	parameter PERIOD = 100; // period = length of clock
	initial begin
		clk <= 0;
		forever #(PERIOD/2) clk = ~clk;
	end

	Filter dut (.*); // ".*" Implicitly connects all ports to variables with matching names

	initial begin

		repeat (10) @(posedge clk);
		$stop; // End simulation
	end
endmodule
*/