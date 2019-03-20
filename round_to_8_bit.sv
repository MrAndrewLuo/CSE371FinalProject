module round_to_8_bit #(parameter PRECISION = 16) 
(
input logic signed [PRECISION - 1:0] in,
output logic [7:0] out
);
logic [PRECISION:0] in_neg;
assign in_neg = (~in + 1);

always_comb begin
	if (in > 255)  out = 255; 
	else if (in < -255)  out = 255;
	else if (in < 0) out = in_neg;
	else out = in;
	end
endmodule

module round_to_8_bit_testbench();
 logic signed [16 - 1:0] in;
 logic [7:0] out;

 round_to_8_bit dut (.*);
 	initial begin
		in <= 50; #10; 
		in <= 255; #10;
		in <= 300; #10;
		in <= -20; #10;
		in <= -300; #10;
		in <= 0; #10;
		$stop; // End simulation
	end

endmodule