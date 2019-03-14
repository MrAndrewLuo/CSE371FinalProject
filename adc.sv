/*
Description:
Driver for AD7928 ADC on DE1_SoC board.
See accompanying tutorial document for details.
*/

module ADC
	// parameters
	// coding (0: two's complement, 1: straight binary)
	// range (0: 0V-5V, 1: 0V-2.5V)
	#(parameter CODING = 1'b1, parameter RANGE = 1'b0)
	
	// inputs and outputs
	(clock, reset, ADC_CS_N, ADC_DIN, ADC_SCLK, ADC_DOUT, data0);

	// interface inputs / outputs
	input clock, reset;          // clock (50MHz) and reset
	// connect to top level pins
	output [11:0] data0;
	output reg ADC_CS_N;         // ADC chip selection
	output reg ADC_DIN;          // ADC serial data in (to ADC)
	output reg ADC_SCLK;         // ADC serial clock
	input ADC_DOUT;              // ADC serial data out (from ADC)

	// states
	parameter QUIET0 = 3'b000, QUIET1 = 3'b001, QUIET2 = 3'b010;
	parameter CYCLE0 = 3'b100, CYCLE1 = 3'b101, CYCLE2 = 3'b110, CYCLE3 = 3'b111;
	
	// internal state holding elements
	reg [7:0][11:0] data; // ADC data out, 8 channels, 12 bits per channel
	reg [2:0] state;   // present state
	reg [2:0] addr;    // present channel address
	reg [3:0] count;   // present count
	reg [14:0] buffer; // present buffer contents
	
	assign data0 = data[0];

	// initial values
	initial begin
		ADC_CS_N <= 1'b1;
		ADC_DIN <= 1'b0;
		ADC_SCLK <= 1'b1;
		state <= QUIET0;
		addr <= 3'b0;
		count <= 4'b0;
		buffer <= 15'b0;
	end
	
	// intermediate values
	wire [3:0] count_incr; // count + 1    
	reg ctrl;              // present control bit
	
	// determine count_incr
	assign count_incr = count + 1'b1;
	
	// determine ctrl
	always @(*) case (count)
		4'b0000: ctrl = 1'b1;    // WRITE	
		4'b0001: ctrl = 1'b0;    // SEQ
		4'b0010: ctrl = 1'bx;    // DON'T CARE
		4'b0011: ctrl = addr[2]; // ADD2
		4'b0100: ctrl = addr[1]; // ADD1
		4'b0101: ctrl = addr[0]; // ADD0
		4'b0110: ctrl = 1'b1;    // PM1
		4'b0111: ctrl = 1'b1;    // PM0
		4'b1000: ctrl = 1'b0;    // SHADOW
		4'b1001: ctrl = 1'bx;    // DON'T CARE
		4'b1010: ctrl = RANGE;   // RANGE
		4'b1011: ctrl = CODING;  // CODING
		default: ctrl = 1'bx;    // DON'T CARE
	endcase
	
	// transitions for state holding elements
	always @(posedge clock)
		if (reset) begin
			ADC_CS_N <= 1'b1;
			ADC_DIN <= 1'b0;
			ADC_SCLK <= 1'b1;
			state <= QUIET0;
			addr <= 3'b0;
			count <= 4'b0;
			buffer <= 15'b0;
		end else begin
			case (state)
				QUIET0: begin // first clock cycle of quiet period, xfer buffer to data
					state <= QUIET1;
					data[buffer[14:12]] <= buffer[11:0];
				end

				QUIET1: begin
					state <= QUIET2;
				end

				QUIET2: begin // end the quiet period by bringing CS low and setting up first data bit
					state <= CYCLE0;
					ADC_CS_N <= 1'b0;
					ADC_DIN <= ctrl;
					count <= count_incr;
					end

				CYCLE0: begin // first clock cycle of serial data xfer cycle, bring SCLK low
					state <= CYCLE1;
					ADC_SCLK <= 1'b0;
				end

				CYCLE1: begin
					state <= CYCLE2;
				end

				CYCLE2: begin // bring SCLK high
					state <= CYCLE3;
					ADC_SCLK <= 1'b1;
				end

				CYCLE3: begin // get data in and prepare for next cycle or transition back to quiet
					if (count == 4'b1111) begin // back to quiet
						state <= QUIET0;
						ADC_CS_N <= 1'b1;
						addr <= addr + 1'b1;
					end else begin
						state <= CYCLE0;
					end
					ADC_DIN <= ctrl;
					buffer <= {buffer[13:0], ADC_DOUT};
					count <= count_incr;
				end
			endcase
		end
endmodule
