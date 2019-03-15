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
	output logic		     [6:0]		HEX1,
	output logic		     [6:0]		HEX2,
	output logic		     [6:0]		HEX3,
	output logic		     [6:0]		HEX4,
	output logic		     [6:0]		HEX5,
	output logic		           		LEDR,

	// *** User inputs ***
	input logic 		     [2:0]		KEY, // Key[2] reserved for reset, key[3] for auto-focus.
	input logic			     [8:0]		SW   // SW[9] reserved for auto-focus mode.
);
	
	localparam PRECISION = 16;

	// Simple graphics hack
	logic [27:0] delay [1:0];
	logic [27:0] prev_delay0;
	logic [7:0] r, g, b; 
	logic signed [PRECISION - 1:0] r16, g16, b16;
	
	always_ff @(posedge VGA_CLK) begin		
		r <= prev_delay0[27:20];
		g <= prev_delay0[19:12];
		b <= prev_delay0[11:4];
		r16 <= {8'b0, r};
		g16 <= {8'b0, g};
		b16 <= {8'b0, b};
	end
	
	// sliding window operators to obtain proper buffers, *b are blurred versions
	// rgb buffer
	logic signed [PRECISION - 1:0] buffer_3_red [2:0][2:0];	
	sliding_window #(3, WIDTH, PRECISION) kernel_in_3_red (.reset(reset), .clk(VGA_CLK), .pixel_in(r16), .buffer(buffer_3_red));
	logic signed [PRECISION - 1:0] buffer_3_green [2:0][2:0];	
	sliding_window #(3, WIDTH, PRECISION) kernel_in_3_green (.reset(reset), .clk(VGA_CLK), .pixel_in(g16), .buffer(buffer_3_green));
	logic signed [PRECISION - 1:0] buffer_3_blue [2:0][2:0];	
	sliding_window #(3, WIDTH, PRECISION) kernel_in_3_blue (.reset(reset), .clk(VGA_CLK), .pixel_in(b16), .buffer(buffer_3_blue));
	
	// gray buffer
	logic signed [PRECISION - 1:0] buffer_3_gray_buff [2:0][2:0];	
	logic signed [PRECISION - 1:0] buffer_3_gray [2:0][2:0];	
	//sliding_window #(3, WIDTH, PRECISION) kernel_in_3_gray (.reset(0), .clk(VGA_CLK), .pixel_in(grayscale16), .buffer(buffer_3_gray));
	genvar i, j;
	generate
		for (i = 0; i < 3; i++) begin: gray_filler_row
			for (j = 0; j < 3; j++) begin: gray_filler_col
				logic [23:0] rgb, rgb_buff;
				always_ff @(posedge VGA_CLK) rgb_buff <= {buffer_3_red[i][j][7:0], buffer_3_green[i][j][7:0], buffer_3_blue[i][j][7:0]};
				always_ff @(posedge VGA_CLK) rgb <= rgb_buff;
				to_grayscale gray_filter(.clk(VGA_CLK), .rgb(rgb), .gray(buffer_3_gray_buff[i][j]));
				
				always_ff @(posedge VGA_CLK) buffer_3_gray[i][j] <= buffer_3_gray_buff[i][j];
			end
		end
	endgenerate
	
	/******** GREY CONVOLUTIONS ********/
	// blur kernel
	logic signed [PRECISION-1:0] blur_out;
	logic [7:0] blur_out_8_bit;
	round_to_8_bit #(PRECISION) rounder (.in(blur_out >>> 4), .out(blur_out_8_bit));
	stream_kernel_3 #(
		1, 2, 1,
		2, 4, 2,
		1, 2, 1,
		PRECISION, WIDTH
	) blur_kernel (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_gray),
		.out(blur_out),
		.out_rounded()
	);
	
	// identity kernel
	logic signed [7:0] identity_out_8_bit;
	stream_kernel_3 #(
		0, 0, 0,
		0, 1, 0,
		0, 0, 0,
		PRECISION, WIDTH
	) identity_kernel (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_gray),
		.out(),
		.out_rounded(identity_out_8_bit)
	);
	
	// horizontal edge
	logic signed [PRECISION - 1:0] horz_out;
	logic signed [7:0] horz_out_8_bit;
	// convolutions
	stream_kernel_3 #(
		1, 2, 1,
		0, 0, 0,
		-1, -2, -1,
		PRECISION, WIDTH
	) horz_kernel (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_gray),
		.out(horz_out),
		.out_rounded(horz_out_8_bit)
	);
	
	// vertical edge
	logic signed [PRECISION - 1:0] vert_out;
	logic signed [7:0] vert_out_8_bit;
	// convolutions
	stream_kernel_3 #(
		-1, 0, 1,
		-2, 0, 2,
		-1, 0, 1,
		PRECISION, WIDTH
	) vert_kernel (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_gray),
		.out(vert_out),
		.out_rounded(vert_out_8_bit)
	);
	
	// horizontal edge, less pronounced
	logic signed [PRECISION - 1:0] horz_out_soft;
	logic signed [7:0] horz_out_soft_8_bit;
	// convolutions
	stream_kernel_3 #(
		0, 1, 0,
		0, 0, 0,
		0, -1, 0,
		PRECISION, WIDTH
	) horz_soft_kernel (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_gray),
		.out(horz_out_soft),
		.out_rounded(horz_out_soft_8_bit)
	);
	
	// vertical edge, less pronounced
	logic signed [PRECISION - 1:0] vert_out_soft;
	logic signed [7:0] vert_out_soft_8_bit;
	// convolutions
	stream_kernel_3 #(
		0, 0, 0,
		-1, 0, 1,
		0, 0, 0,
		PRECISION, WIDTH
	) vert_soft_kernel (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_gray),
		.out(vert_out_soft),
		.out_rounded(vert_out_soft_8_bit)
	);
	
	// classic edge, non-sobel
	logic signed [7:0] classic_edge_8_bit;
	// convolutions
	stream_kernel_3 #(
		-1, -1, -1,
		-1, 8, -1,
		-1, -1, -1,
		PRECISION, WIDTH
	) classic_edge_kernel (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_gray),
		.out(),
		.out_rounded(classic_edge_8_bit)
	);
	
	// sobel operator
	logic [7:0] sobel_8_bit, sobel_soft_8_bit;
	sobel_operator #(PRECISION) sobel (.clk(VGA_CLK), .vert_in(vert_out), .horz_in(horz_out), .out(sobel_8_bit));
	sobel_operator #(PRECISION) sobel_soft (.clk(VGA_CLK), .vert_in(vert_out_soft), .horz_in(horz_out_soft), .out(sobel_soft_8_bit));

	/******** COLOR CONVOLUTIONS ********/
	// blur kernels
	logic signed [PRECISION-1:0] blur_out_r;
	logic [7:0] blur_out_r_8_bit;
	round_to_8_bit #(PRECISION) blur_r_divide (.in(blur_out_r >>> 4), .out(blur_out_r_8_bit));
	stream_kernel_3 #(
		1, 2, 1,
		2, 4, 2,
		1, 2, 1,
		PRECISION, WIDTH
	) blur_kernel_r (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_red),
		.out(blur_out_r),
		.out_rounded()
	);
	logic signed [PRECISION-1:0] blur_out_g;
	logic [7:0] blur_out_g_8_bit;
	round_to_8_bit #(PRECISION) blur_g_divide (.in(blur_out_g >>> 4), .out(blur_out_g_8_bit));
	stream_kernel_3 #(
		1, 2, 1,
		2, 4, 2,
		1, 2, 1,
		PRECISION, WIDTH
	) blur_kernel_g (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_green),
		.out(blur_out_g),
		.out_rounded()
	);
	logic signed [PRECISION-1:0] blur_out_b;
	logic [7:0] blur_out_b_8_bit;
	round_to_8_bit #(PRECISION) blur_b_divide (.in(blur_out_b >>> 4), .out(blur_out_b_8_bit));
	stream_kernel_3 #(
		1, 2, 1,
		2, 4, 2,
		1, 2, 1,
		PRECISION, WIDTH
	) blur_kernel_b (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_blue),
		.out(blur_out_b),
		.out_rounded()
	);
	
	// sharpen kernels
	logic [7:0] sharpen_r_8_bit;
	stream_kernel_3 #(
		0, -1, 0,
		-1, 5, -1,
		0, -1, 0,
		PRECISION, WIDTH
	) sharpen_kernel_r (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_red),
		.out(),
		.out_rounded(sharpen_r_8_bit)
	);
	logic [7:0] sharpen_g_8_bit;
	stream_kernel_3 #(
		0, -1, 0,
		-1, 5, -1,
		0, -1, 0,
		PRECISION, WIDTH
	) sharpen_kernel_g (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_green),
		.out(),
		.out_rounded(sharpen_g_8_bit)
	);
	logic [7:0] sharpen_b_8_bit;
	stream_kernel_3 #(
		0, -1, 0,
		-1, 5, -1,
		0, -1, 0,
		PRECISION, WIDTH
	) sharpen_kernel_b (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_blue),
		.out(),
		.out_rounded(sharpen_b_8_bit)
	);
	
	/******** CUSTOM CONVOLUTIONS ********/
	logic signed [PRECISION - 1:0] custom_kernel [2:0][2:0];
	custom_kernel #(PRECISION) custom_kernel_module (.*);

	logic [7:0] custom_r_8_bit;
	stream_kernel_3_mutable #(
		PRECISION, WIDTH
	) custom_r (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_red),
		.kernel(custom_kernel),
		.out(),
		.out_rounded(custom_r_8_bit)
	);
	logic [7:0] custom_g_8_bit;
	stream_kernel_3_mutable #(
		PRECISION, WIDTH
	) custom_g (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_green),
		.kernel(custom_kernel),
		.out(),
		.out_rounded(custom_g_8_bit)
	);
	logic [7:0] custom_b_8_bit;
	stream_kernel_3_mutable #(
		PRECISION, WIDTH
	) custom_b (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_blue),
		.kernel(custom_kernel),
		.out(),
		.out_rounded(custom_b_8_bit)
	);
	
	logic [7:0] custom_gray_8_bit;
	stream_kernel_3_mutable #(
		PRECISION, WIDTH
	) custom_gray (
		.clk(VGA_CLK),
		.buffer_3(buffer_3_gray),
		.kernel(custom_kernel),
		.out(),
		.out_rounded(custom_gray_8_bit)
	);
	
	// Before and after delays, outputs
	always_ff @(posedge VGA_CLK) begin
		{oVGA_R, oVGA_G, oVGA_B, oVGA_HS, oVGA_VS, oVGA_SYNC_N, oVGA_BLANK_N} <= delay[1];
		prev_delay0 <= delay[0];
		delay[0] <= {iVGA_R, iVGA_G, iVGA_B, iVGA_HS, iVGA_VS, iVGA_SYNC_N, iVGA_BLANK_N};
	end
	
	always_ff @(posedge VGA_CLK) begin		
		delay[1][3:0] <= delay[0][3:0];
		
		case (SW[3:0]) 
			// grey and edge detection
			1: delay[1][27:4] <= {3{buffer_3_gray[1][1][7:0]}};  // just grayscale image
			2: delay[1][27:4] <= {3{identity_out_8_bit}};	// identity grayscale
			3: delay[1][27:4] <= {3{horz_out_8_bit}};			// horizontal edge
			4: delay[1][27:4] <= {3{vert_out_8_bit}};			// vertical edge
			5: delay[1][27:4] <= {3{sobel_8_bit}};				// sobel edge
			6: delay[1][27:4] <= {3{horz_out_soft_8_bit}};	// horizontal edge, less prounounced
			7: delay[1][27:4] <= {3{vert_out_soft_8_bit}};	// vertical edge, less pronounced
			8: delay[1][27:4] <= {3{sobel_soft_8_bit}};	   // sobel edge, less pronounced
			9: delay[1][27:4] <= {3{classic_edge_8_bit}};	// classic "edge" filter
			10: delay[1][27:4] <= {3{blur_out_8_bit}};	   // gaussian blur grey
			
			// rgb 
			11: delay[1][27:4] <= {blur_out_r_8_bit, blur_out_g_8_bit, blur_out_b_8_bit};		// gaussian blur rgb
			12: delay[1][27:4] <= {sharpen_r_8_bit, sharpen_g_8_bit, sharpen_b_8_bit};			// sharpen rgb
			
			// custom kernels
			13: delay[1][27:4] <= {custom_r_8_bit, custom_g_8_bit, custom_b_8_bit};
			14: delay[1][27:4] <= {3{custom_gray_8_bit}};
			
			// e.g. 0
			default: delay[1][27:4] <= delay[0][27:4];
		endcase
	end
	
	assign HEX3 = '1;
endmodule

module custom_kernel
#(parameter PRECISION = 16)
(
input logic VGA_CLK,
input logic [8:0] SW,
input logic [2:0] KEY,
output logic [6:0] HEX1, HEX2, HEX4, HEX5,
output logic signed [PRECISION - 1:0] custom_kernel [2:0][2:0],
output logic LEDR
);
	logic reset;
	logic [1:0] x ;
	logic [1:0] y ;
	logic signed [3:0] cur_value , kernel_val, kernel_val_neg;
	logic write;
	
	logic [1:0] x_next ;
	logic [1:0] y_next;

	bin2hex7seg hex_x (x, HEX2);
	bin2hex7seg hex_y (y, HEX1);

	logic [6:0] HEX4_neg, HEX4_pos;
	bin2hex7seg hex_val1 (kernel_val[2:0], HEX4_pos);
	
	assign kernel_val_neg = (~kernel_val + 1);
	bin2hex7seg hex_val2 (kernel_val_neg[2:0], HEX4_neg);
	
	logic KEY0, KEY1;
	button_input KEY0m (.clk(VGA_CLK), .reset, .button(KEY[0]), .pressed(KEY0));
	button_input KEY1m (.clk(VGA_CLK), .reset, .button(KEY[1]), .pressed(KEY1));

	always_comb begin
		if (x + 1 == 2'b11) x_next = 0; else x_next = x + 1;
		if (y + 1 == 2'b11) y_next = 0; else y_next = y + 1;
		
		if (cur_value < 0) begin
			HEX5 = 7'b0111111;
			HEX4 = HEX4_neg;
		end
		else begin
			HEX5 = 7'b1111111;
			HEX4 = HEX4_pos;
		end
	end
	always_ff @(posedge VGA_CLK) begin
		if (reset) begin
			custom_kernel[0][0] <= 1;
			custom_kernel[0][1] <= 1;
			custom_kernel[0][2] <= 1;
			custom_kernel[1][0] <= 1;
			custom_kernel[1][1] <= 1;
			custom_kernel[1][2] <= 1;
			custom_kernel[2][0] <= 1;
			custom_kernel[2][1] <= 1;
			custom_kernel[2][2] <= 1;

			x <= 0;
			y <= 0;
		end
		else begin
			if (KEY0) x <= x_next; else x <= x;
			if (KEY1) y <= y_next; else y <= y;
			
			if (write) custom_kernel[y][x] <= cur_value;
		end
		
		cur_value <= SW[7:4];
		reset <= ~KEY[2];
		kernel_val <= custom_kernel[y][x];
		write <= SW[8];
	end
	assign LEDR = reset;
endmodule

module to_grayscale(input logic clk, input logic[23:0] rgb, output logic [15:0] gray);
		logic [31:0] grayscale;
		assign grayscale = (rgb[23:16] / 4 + (rgb[15:8] / 8) * 5  + rgb[7:0] / 10);
		always_ff @(posedge clk) gray <= grayscale[15:0];
endmodule

module custom_kernel_testbench();
	localparam PRECISION = 16;
	
	logic VGA_CLK, clk;
	assign VGA_CLK = clk;
	
	logic [8:0] SW;
	logic [2:0] KEY;
	logic [6:0] HEX1, HEX2, HEX4, HEX5;
	logic signed [PRECISION - 1:0] custom_kernel [2:0][2:0];
	logic LEDR;
	
	// Set up the clock.
	parameter PERIOD = 40; // period = length of clock
	initial begin
		clk = 0;
		forever #(PERIOD/2) clk = ~clk;
	end
	
	custom_kernel dut (.*); // ".*" Implicitly connects all ports to variables with matching names
	
	integer i;
	initial begin
		KEY[2] <= 0; KEY[1] <= 1; KEY[0] <= 1; SW <= '0; @(posedge clk); KEY[2] <= 1; @(posedge clk);
		KEY[0] <= 0; @(posedge clk); @(posedge clk); @(posedge clk); KEY[0] <= 1; @(posedge clk);
		KEY[1] <= 0; @(posedge clk); @(posedge clk); @(posedge clk); KEY[1] <= 1; @(posedge clk);

		for(i = 0; i < 2000; i++) @(posedge clk);
		$stop; // End simulation
	end
endmodule

`timescale 1 ps / 1 ps
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
	logic			     [7:0]		SW;   // SW[9] reserved for auto-focus mode.
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

		for(i = 0; i < 2000; i++) @(posedge clk);
		$stop; // End simulation
	end
endmodule

