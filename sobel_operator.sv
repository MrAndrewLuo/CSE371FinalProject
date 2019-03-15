module 
sobel_operator
#(parameter N = 15, parameter PRECISION = 24)
(
input logic clk,
input logic signed [15:0] vert_in, 
input logic signed [15:0] horz_in,
output logic [7:0] out 
);
logic signed [PRECISION - 1:0] vert1 ;
logic signed [PRECISION - 1:0] horz1 ;
assign vert1 = vert_in;
assign horz1 = horz_in; 

logic signed [PRECISION - 1:0] vert2 ;
logic signed [PRECISION - 1:0] horz2 ; 
logic signed [PRECISION - 1:0] sum2 ;

assign vert2 = vert1 * vert1;
assign horz2 = horz1 * horz1;
assign sum2 = vert2 + horz2 + 1; // + 1 to avoid divide by 0's

logic [PRECISION - 1:0] newton_iterations [N - 1:0];
logic [PRECISION - 1:0] targets [N - 1:0];


always_ff @(posedge clk) newton_iterations[0] <= (sum2 >> 1) + (sum2 >> 2) + 1; // initial guess
always_ff @(posedge clk) targets[0] <= sum2; 
genvar i;
generate
	for (i = 1; i < N; i++) begin: newton_gen
		always_ff @(posedge clk) begin
			newton_iterations[i] <= ((targets[i - 1]  / newton_iterations[i - 1]) + newton_iterations[i - 1]) >> 1;
			targets[i] <= targets[i - 1];
		end
	end
endgenerate

always_comb begin
	if (newton_iterations[N - 1] > 255) out = 255; else out = newton_iterations[N - 1];
end

endmodule

module sobel_operator_testbench
();
	localparam N = 15;
	// cool andrew
	logic clk;
	logic signed [23:0] vert_in;
	logic signed [23:0] horz_in;
	logic [7:0] out;
	
	sobel_operator #(N, 24) dut (.*);
	
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
		for (i = 0; i < 200; i++) @(posedge clk);
		$stop;
	end //initial
endmodule