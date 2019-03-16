// Final Project 
// Capture Single Image for Convolution

module Capture(clk, reset, s, almostDoneWr, wrAddr, maxWr);
	input logic clk, reset, s, almostDoneWr;
	output logic [22:0] wrAddr, maxWr;
	
	enum {Idle, wrSwap, Done} ps, ns;
	
	always_comb begin
		case(ps)
			Idle 	:	begin 
							wrAddr = 0;
							maxWr = 640 * 480;
							if (s) ns = wrSwap;
							else   ns = Idle;
						end 
					
			wrSwap	:	begin 
							wrAddr = 0;
							maxWr = 640 * 480;
							ns = wrSwap;
							if (almostDoneWr) begin
								wrAddr = 640 * 480;
								maxWr = 2 * 640 * 480;
								ns = Done;
							end
						end
					
			Done	:	begin 
							wrAddr = (640 * 480) + 1;
							maxWr = (2 * 640 * 480) + 1;
							ns = Done;
							if (~s & almostDoneWr) begin
								wrAddr = 0;
								maxWr = 640 * 480;
								ns = Idle;
							end
						end
			default: ns = Idle;
		endcase 
	end
	
	always_ff @(posedge clk) begin 
		if (~reset) ps <= Idle;
		else ps <= ns;
	end

endmodule 

module Capture_testbench();
	logic clk, reset, s, almostDoneWr;
	logic [22:0] wrAddr, maxWr;

	initial begin
		clk <= 0;
		forever #(10) clk <= ~clk;
	end

	Capture dut (.*);

	initial begin
		s <= 0; almostDoneWr <= 0;
		reset <= 1; @(posedge clk);
		reset <= 0; @(posedge clk);
		@(posedge clk);
		s <= 1; @(posedge clk);
		@(posedge clk);
		almostDoneWr <= 1; @(posedge clk);
		almostDoneWr <= 0; @(posedge clk);
		@(posedge clk);
		s <= 0; @(posedge clk);
		almostDoneWr <= 1; @(posedge clk);
		almostDoneWr <= 0; @(posedge clk);
		$stop;
	end
endmodule