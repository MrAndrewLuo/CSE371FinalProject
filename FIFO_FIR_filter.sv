module FIFO_FIR_filter #(parameter WIDTH = 24, parameter N = 7) 
							   (
									input logic clk, reset,
									input logic signed [WIDTH - 1:0] sample_in,
									output logic signed [WIDTH - 1:0] sample_out
								);
	
	logic [WIDTH - 1:0] avg_sample_in;
	assign avg_sample_in = $signed(sample_in) / $signed(2 ** N);
	
	logic [WIDTH - 1:0] fifo_in, fifo_out;
	assign fifo_in = avg_sample_in;
	
	logic read, write, full, empty, almost_full;
	
	fifo #(WIDTH, N) buff 
	(.clk(clk), .rst(reset), .read, .write, 
	 .wdata(fifo_in), .rdata(fifo_out), .full, .almost_full, .empty);

	always_comb begin
		write = 1;
		read = almost_full;
	end
							
	logic [WIDTH - 1:0] accumulator;	
	logic [WIDTH - 1:0] sum_node_1, sum_node_2;
	assign sum_node_1 = $signed(fifo_in) - $signed(fifo_out);
	assign sum_node_2 = sum_node_1 + accumulator;
	assign sample_out = sum_node_2;
	
	always_ff @(posedge clk) begin
		if (reset) accumulator <= 0;
		else accumulator <= sum_node_2;
	end
endmodule

module FIFO_FIR_filter_testbench ();
	localparam WIDTH=24;

	logic reset, clk; 
	logic signed [WIDTH - 1:0] sample_in;
	logic signed [WIDTH - 1:0] sample_out;
	
	FIFO_FIR_filter #(WIDTH, 3) dut (.*);
	
	// Set up the clock.
	parameter CLOCK_PERIOD=100;
	initial clk=1;
	always begin
		#(CLOCK_PERIOD/2);
		clk = ~clk;
	end
	
	integer i;
	initial begin
		// reset but idle for a few periods, done should be off
		reset <= 1; sample_in <= -100; @(posedge clk); reset <= 0; @(posedge clk);
		sample_in <= 200; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		sample_in <= 300; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		sample_in <= 400; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		sample_in <= 500; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		sample_in <= -600; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		sample_in <= -700; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		sample_in <= -800; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		sample_in <= -900; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		sample_in <= 1000; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		sample_in <= 1100; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		sample_in <= 1200; @(posedge clk); $write("Time: %3d, sample_out: %5d", $time, sample_out);
		@(posedge clk); @(posedge clk); @(posedge clk);
		$stop;
	end //initial
endmodule