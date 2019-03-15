module round_to_8_bit #(parameter PRECISION = 16) 
(
input logic signed [PRECISION - 1:0] in,
output logic [7:0] out
);
always_comb begin
	if (in > 255)  out = 255; 
	else if (in < -255)  out = 255;
	else if (in < 0) out = ~in + 1;
	else out = in;
	end
endmodule