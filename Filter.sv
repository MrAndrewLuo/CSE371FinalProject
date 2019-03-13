// Warning: the Terasic VGA controller appears to have a few off-by-one errors.  If your code is very 
// sensitive to the EXACT number of pixels per line, you may have issues.  You have been warned!

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

	// Simple graphics hack
	logic [27:0] delay [1:0];
	logic [7:0] delta_R;
	logic [7:0] delta_G;
	logic [7:0] delta_B;
	logic [7:0] grayscale;
	logic signed [15:0] grayscale16;
	logic [15:0] r, g, b;
	logic [27:0] prev_delay0;

	// Before and after delays.
	always_ff @(posedge VGA_CLK) begin
		{oVGA_R, oVGA_G, oVGA_B, oVGA_HS, oVGA_VS, oVGA_SYNC_N, oVGA_BLANK_N} <= delay[1];
		prev_delay0 <= delay[0];
		delay[0] <= {iVGA_R, iVGA_G, iVGA_B, iVGA_HS, iVGA_VS, iVGA_SYNC_N, iVGA_BLANK_N};
	end
	
	// simple processing
	always_comb begin
		if (delay[0][27:20] > prev_delay0[27:20])
			delta_R = delay[0][27:20] - prev_delay0[27:20];
		else
			delta_R = prev_delay0[19:12] - delay[0][19:12];
		if (delay[0][19:12] > prev_delay0[19:12])
			delta_G = delay[0][19:12] - prev_delay0[19:12];
		else
			delta_G = prev_delay0[11:4] - delay[0][11:4];
		if (delay[0][11:4] > prev_delay0[11:4])
			delta_B = delay[0][11:4] - prev_delay0[11:4];
		else
			delta_B = prev_delay0[11:4] - delay[0][11:4];
		 
		grayscale = prev_delay0[27:20] / 4 + prev_delay0[19:12] / 8 * 5  + prev_delay0[11:4] / 10;
	end
	
	// convolutions
	logic signed [15:0] buffer_3 [2:0][2:0];
	logic signed [15:0] buffer_3_buffered [2:0][2:0];
	logic signed [15:0] identity_kernel [2:0][2:0];
	assign identity_kernel[0][0] = 0;
	assign identity_kernel[0][1] = 0;
	assign identity_kernel[0][2] = 0;
	assign identity_kernel[1][0] = 0;
	assign identity_kernel[1][2] = 0;
	assign identity_kernel[2][0] = 0;
	assign identity_kernel[2][1] = 0;
	assign identity_kernel[2][2] = 0;
	assign identity_kernel[1][1] = 1;
	logic signed [15:0] identity_out, identity_out_buffered;
	
	logic signed [15:0] horz_edge_kernel [2:0][2:0];
	assign horz_edge_kernel[0][0] = 1;
	assign horz_edge_kernel[0][1] = 0;
	assign horz_edge_kernel[0][2] = -1;
	assign horz_edge_kernel[1][0] = 1;
	assign horz_edge_kernel[1][1] = 0;
	assign horz_edge_kernel[1][2] = -1;
	assign horz_edge_kernel[2][0] = 1;
	assign horz_edge_kernel[2][1] = 0;
	assign horz_edge_kernel[2][2] = -1;
	logic signed [15:0] horz_edge_out, horz_edge_out_buffered;

	logic signed [15:0] vert_edge_kernel [2:0][2:0];
	assign vert_edge_kernel[0][0] = 1;
	assign vert_edge_kernel[0][1] = 1;
	assign vert_edge_kernel[0][2] = 1;
	assign vert_edge_kernel[1][0] = 0;
	assign vert_edge_kernel[1][1] = 0;
	assign vert_edge_kernel[1][2] = 0;
	assign vert_edge_kernel[2][0] = -1;
	assign vert_edge_kernel[2][1] = -1;
	assign vert_edge_kernel[2][2] = -1;
	logic signed [15:0] vert_edge_out, vert_edge_out_buffered;
	
	// sliding window operators
	sliding_window #(3, WIDTH, 16) kernel_in_3 (.reset(0), .clk(VGA_CLK), .pixel_in(grayscale16), .buffer(buffer_3));
	
	// kernels for 3x3 kernels
	kernel_convolution #(3, 16) identity_convolve(.clk(VGA_CLK), .buffer_in(buffer_3_buffered), .kernel_in(identity_kernel), .ans(identity_out));
	
	// line filters
	// TODO: add blur to grayscale image before gaussian
	kernel_convolution #(3, 16) horz_edge_convolve(.clk(VGA_CLK), .buffer_in(buffer_3_buffered), .kernel_in(horz_edge_kernel), .ans(horz_edge_out));	
	kernel_convolution #(3, 16) vert_edge_convolve(.clk(VGA_CLK), .buffer_in(buffer_3_buffered), .kernel_in(vert_edge_kernel), .ans(vert_edge_out));
	
	always_ff @(posedge VGA_CLK) begin
		grayscale16 <= {8'b0, grayscale};
		buffer_3_buffered <= buffer_3;
		identity_out_buffered <= identity_out;
		
		if (vert_edge_out > 0) vert_edge_out_buffered <= vert_edge_out; else if (vert_edge_out > 255) vert_edge_out_buffered <= 255; else vert_edge_out_buffered <= 0;
		if (horz_edge_out > 0) horz_edge_out_buffered <= horz_edge_out; else if (horz_edge_out > 255) horz_edge_out_buffered <= 255; else horz_edge_out_buffered <= 0;
		
		delay[1] <= delay[0];
		if (SW[0]) delay[1][27:20] <= delta_R;
		else if (SW[1]) delay[1][19:12] <= delta_G;
		else if (SW[2]) delay[1][11:4] <= delta_B;
		else if (SW[3]) delay[1][27:4] <= {grayscale, grayscale, grayscale};
		else if (SW[4]) delay[1][27:4] <= {identity_out_buffered[7:0], identity_out_buffered[7:0], identity_out_buffered[7:0]};
		else if (SW[5]) delay[1][27:4] <= {vert_edge_out_buffered[7:0], vert_edge_out_buffered[7:0], vert_edge_out_buffered[7:0]};
		else if (SW[6]) delay[1][27:4] <= {horz_edge_out_buffered[7:0], horz_edge_out_buffered[7:0], horz_edge_out_buffered[7:0]};

	end
	
	assign HEX0 = '1;
	assign HEX1 = '1;
	assign HEX2 = '1;
	assign HEX3 = '1;
	assign HEX4 = '1;
	assign HEX5 = '1;
	assign LEDR = '0;

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

