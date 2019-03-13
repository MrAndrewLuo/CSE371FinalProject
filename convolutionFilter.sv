module convolutionFilter #(parameter WIDTH = 200, HEIGHT = 100, WORD_SIZE = 8) (clk, start, reset, kernel, dataIn, dataOut);
	input logic clk, start, reset;
	input logic  [WORD_SIZE-1:0] kernel  [3][3];
	input logic  [WORD_SIZE-1:0] dataIn  [WIDTH][HEIGHT];
	output logic [WORD_SIZE-1:0] dataOut [WIDTH][HEIGHT];
	output logic done;
	
	enum {standby, process} ps, ns;

	always_ff @(posedge clk) begin
		if (reset || done) begin
			ps <= standby;
			done <= 0;
		end else begin
			ps <= ns;
		end
	end

	always_comb begin
		case (ps)
		
			standby: begin
				if (~done)	ns = process;
				else		ns = standby;
			end
			
			process: begin
				if (done) 	ns = standby;
				else		ns = process;
			end
		endcase
	end
	
	integer curX, curY;
	logic [8:0] a, b, c, d, e, f, g, h, i;
	always_ff @(posedge clk) begin
		if (reset) begin
			ps <= standby;
			done <= 0;
		end else if (ps == process) begin
			for (curY = 0; curY <= HEIGHT - 1; curY++) begin
				for (curX = 0; curX <= WIDTH - 1; curX++) begin
					if ((curX == 0 || curX == WIDTH - 1)|| (curY == 0 || curY == HEIGHT - 1))begin
						dataOut [curX][curY] <= 0; // Perimeter cases
					end else begin
						a = dataIn[curX - 1][curY - 1];
						b = dataIn[curX + 0][curY - 1];
						c = dataIn[curX + 1][curY - 1];
						
						d = dataIn[curX - 1][curY + 0];
						e = dataIn[curX + 0][curY + 0];
						f = dataIn[curX + 1][curY + 0];
						
						g = dataIn[curX - 1][curY + 1];
						h = dataIn[curX + 0][curY + 1];
						i = dataIn[curX + 1][curY + 1];
						
						// x, y
						dataOut [curX][curY] <= ((i * kernel [0][0]) + (h * kernel [1][0]) + (g * kernel [2][0]) + (f * kernel [0][1]) + (e * kernel [1][1]) + (d * kernel [2][1]) + (c * kernel [0][2]) + (b * kernel [1][2]) + (a * kernel [2][2]));
					end
				end
				
			end
			if (curY == (HEIGHT - 2)) begin
				done <= 1;
			end
		end 
	end // end always_ff
endmodule 


module convolutionFilter_testbench() ;
	localparam WIDTH = 640;
	localparam HEIGHT = 480;
	localparam WORD_SIZE = 12;
	localparam KERNEL_SIZE = 3;
	logic [WORD_SIZE-1:0] kernel [KERNEL_SIZE][KERNEL_SIZE];
	logic [WORD_SIZE-1:0] dataIn [WIDTH][HEIGHT];
	logic [WORD_SIZE-1:0] dataOut [WIDTH][HEIGHT];
	logic clk, start, done, reset;

	// Set up the clock.
	parameter PERIOD = 100; // period = length of clock
	initial begin
		clk <= 0;
		forever #(PERIOD/2) clk = ~clk;
	end

	convolutionFilter #(WIDTH, HEIGHT, WORD_SIZE) dut (.*); // ".*" Implicitly connects all ports to variables with matching names
	
	integer i, j;
	initial begin
		for (i = 0; i < KERNEL_SIZE; i++) begin
			for (j = 0; j < KERNEL_SIZE; j++) begin
				kernel[i][j] = (i*KERNEL_SIZE) + j;
			end
		end
		
		for (i = 0; i < WIDTH; i++) begin
			for (j = 0; j < HEIGHT; j++) begin
				dataIn[i][j] = (i*WIDTH) + j;
			end
		end
		
		reset <= 1; @(posedge clk);
		reset <= 0; @(posedge clk);
		start <= 1;
		
		repeat (300) @(posedge clk);
		$stop; // End simulation
	end
endmodule
