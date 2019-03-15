module 
sobel_operator
#(parameter PRECISION = 16)
(
input logic clk,
input logic signed [PRECISION-1:0] vert_in, 
input logic signed [PRECISION-1:0] horz_in,
output logic [7:0] out 
);
logic signed [7:0] vert1 ;
logic signed [7:0] horz1 ;

// do some rounding, our max output is only 255 anyway
// so it's ok to round down if we have too
round_to_8_bit #(PRECISION) round_vert_in (.in(vert_in), .out(vert1));
round_to_8_bit #(PRECISION) round_horz_in (.in(horz_in), .out(horz1));

logic [PRECISION - 1:0] vert2, horz2 ;
logic [PRECISION - 1 + 3:0] vert2_buffered, horz2_buffered ; 

always_ff @(posedge clk) begin
	vert2_buffered <= {3'b0,vert2};
	horz2_buffered <= {3'b0, horz2};
end

square_8 sq_horz(.address(horz1), .clock(clk), .q(horz2));
square_8 sq_vert(.address(vert1), .clock(clk), .q(vert2));

logic [15:0] sum2 ;
always_comb begin
	if (vert2_buffered + horz2_buffered > 16'hFFFF) begin
		sum2 = 16'hFFFF;
	end
	else begin
		sum2 = vert2_buffered + horz2_buffered;
	end
end

logic [7:0] ans;
square_root_16 sqrt(.address(sum2), .clock(clk), .q(ans));

always_ff @(posedge clk) begin
	out <= ans;
end

endmodule

`timescale 1 ps / 1 ps
module sobel_operator_testbench
();
	// cool andrew
	logic clk;
	logic signed [15:0] vert_in;
	logic signed [15:0] horz_in;
	logic [7:0] out;
	
	sobel_operator dut (.*);
	
	// Set up the clock.
	parameter CLOCK_PERIOD=100;
	initial clk=1;
	always begin
		#(CLOCK_PERIOD/2);
		clk = ~clk;
	end
	
	integer i;
	initial begin
		
		vert_in <= 35; horz_in <= 35; @(posedge clk);
		vert_in <= 1; horz_in <= 1; @(posedge clk);
		vert_in <= 0; horz_in <= 0; @(posedge clk);
		vert_in <= 1; horz_in <= 0; @(posedge clk);
		vert_in <= 244; horz_in <= 35; @(posedge clk);
		vert_in <= 123; horz_in <= 35; @(posedge clk);
		vert_in <= 255; horz_in <= 255; @(posedge clk);
		@(posedge clk); 
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		//for (i = 0; i < 200; i++) @(posedge clk);
		$stop;
	end //initial
endmodule