module stream_kernel_3
#(
parameter k0_0 = 0, 
parameter k0_1 = 0, 
parameter k0_2 = 0, 
parameter k1_0 = 0, 
parameter k1_1 = 1, 
parameter k1_2 = 0, 
parameter k2_0 = 0, 
parameter k2_1 = 0, 
parameter k2_2 = 0,
parameter PRECISION = 16,
parameter WIDTH = 640
)
(
input clk,
input logic signed [PRECISION - 1:0] buffer_3 [2:0][2:0],
output logic signed [PRECISION - 1:0] out,
output logic [7:0] out_rounded
);

// kernel 
logic signed [PRECISION - 1:0] kernel [2:0][2:0];
assign kernel[0][0] = k0_0[7:0];
assign kernel[0][1] = k0_1[7:0];
assign kernel[0][2] = k0_2[7:0];
assign kernel[1][0] = k1_0[7:0];
assign kernel[1][1] = k1_1[7:0];
assign kernel[1][2] = k1_2[7:0];
assign kernel[2][0] = k2_0[7:0];
assign kernel[2][1] = k2_1[7:0];
assign kernel[2][2] = k2_2[7:0];

// calculation
logic signed [PRECISION - 1:0] ans;
kernel_convolution #(3, PRECISION) identity_convolve(.clk, .buffer_in(buffer_3), .kernel_in(kernel), .ans);

always_ff @(posedge clk) begin
	out <= ans;
end

round_to_8_bit #(PRECISION) rounder (.in(out), .out(out_rounded));
endmodule