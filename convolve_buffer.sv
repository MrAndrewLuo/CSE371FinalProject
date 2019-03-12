module convolve_buffer
#(parameter WIDTH = 5, parameter HEIGHT = 5, parameter KERNEL_SIZE=3)
(
input logic clk, reset, enable,
input logic signed [47:0] buffer_in [HEIGHT-1:0][WIDTH-1:0],
input logic signed [47:0] kernel_in [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0],
output logic done,
output logic signed [47:0] buffer_out [HEIGHT-1:0][WIDTH-1:0]
);
endmodule

module
convolve_buffer_controlpath
#(parameter WIDTH = 640, parameter HEIGHT = 480, parameter KERNEL_SIZE=3) 
(
	input logic clk, reset, enable,
	output logic [31:0] w, h, calc, load_kernel, done
);

	enum {S_idle, S_do} ps, ns;

	// state transitions
	always_ff @(posedge clk) begin
		if (reset) ps <= S_idle;
		else ps <= ns;
	end
	
	always_comb begin
		if (ps == S_idle & enable) begin
			ns = S_do;
		end
		else begin
			ns = S_idle;
		end
	end
	
	// output logic
	always_ff @(posedge clk) begin
		if (reset) begin
			w <= KERNEL_SIZE / 2;
			h <= KERNEL_SIZE / 2;
			calc <= 0;
			load_kernel <= 1;
			done <= 0;
		end
		else if (ps == S_do) begin
			load_kernel <= 0;
			calc <= 1;
			if (w + 1 >= WIDTH - KERNEL_SIZE / 2) begin
				// not safe to increment height
				if (h + 1 >= HEIGHT - KERNEL_SIZE / 2) begin
					w <= w;
					h <= h;
					done <= 1;
				end
				else begin
					h <= h + 1;
					w <= 0;
					done <= 0;
				end
			end
			else begin
				w <= w + 1;
				h <= h;
				done <= 0;
			end
		end
	end

endmodule
