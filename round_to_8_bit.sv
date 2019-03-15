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
	else if (in < 0) out = in_neg[7:0];
	else out = in[7:0];
	end
endmodule