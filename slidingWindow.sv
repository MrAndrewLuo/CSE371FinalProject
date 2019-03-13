// https://sistenix.com/sobel.html

module #(parameter WORD_SIZE = 8, ROW_SIZE = 10, BUFFER_SIZE = 3) slidingWindow (
	input logic clk, reset,
	input logic [WORD_SIZE-1:0] inputPixels,
	output logic [BUFFER_SIZE-1:0][WORD_SIZE-1:0] window [BUFFER_SIZE-1:0]
	);
	
	// buffer
	logic [(BUFFER_SIZE-1)*WORD_SIZE-1:0] buffer[ROW_SIZE-1:0];
	logic [$clog2(ROW_SIZE)-1:0] ptr;
	
	always_ff @(posedge clk) begin
		if (reset) begin
			ptr  <= 0; // Assumes buffer size 3
		    window[0][0] <= 0;
		    window[0][1] <= 0;
		    window[0][2] <= 0;
		    window[1][0] <= 0;
		    window[1][1] <= 0;
		    window[1][2] <= 0;
		    window[2][0] <= 0;
		    window[2][1] <= 0;
		    window[2][2] <= 0;
		end else begin
		    window[0][0] <= inputPixels;
		    window[0][1] <= 0;
		    window[0][2] <= 0;
		    window[1][0] <= 0;
		    window[1][1] <= 0;
		    window[1][2] <= 0;
		    window[2][0] <= 0;
		    window[2][1] <= 0;
		    window[2][2] <= 0;
			
			buffer[ptr] <= window[BUFFER_SIZE-1][BUFFER_SIZE-2:0];
			window[0][BUFFER_SIZE-1:1] <= buffer[ptr];
			if (ptr < ROW_SIZE - BUFFER_SIZE) 	ptr <= ptr + 1;
			else								ptr <= 0;
		end
		
	end
endmodule 

/*
module slidingWindow_testbench();
	window[0][0] <= Pixels;
	logic clk, reset,
	logic [WORD_SIZE-1:0] Pixels,
	logic [BUFFER_SIZE-1:0][WORD_SIZE-1:0] window [BUFFER_SIZE-1:0]

	// Set up the clock.
	parameter PERIOD = 100; // period = length of clock
	initial begin
		clk <= 0;
		forever #(PERIOD/2) clk = ~clk;
	end

	slidingWindow dut (.*); // ".*" Implicitly connects all ports to variables with matching names

	initial begin

		repeat (10) @(posedge clk);
		$stop; // End simulation
	end
endmodule
*/