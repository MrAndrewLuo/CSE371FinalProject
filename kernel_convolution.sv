module kernel_convolution
#(
parameter KERNEL_SIZE = 3,
parameter WIDTH = 640,
parameter HEIGHT = 480
)
(
input logic clock, enable,
input logic load_reg,

// rgb with 10 bits each (signed integer)
input signed [HEIGHT - 1:0][WIDTH - 1:0] input_img [29:0], 
	
// assume 5 bit signed integer for each input
// kernel dimensions are w x h x c
input signed [KERNEL_SIZE - 1:0][KERNEL_SIZE - 1:0][2:0] kernel [4:0],
	
output signed [HEIGHT - 1:0][WIDTH - 1:0] output_img [29:0],

output logic done
);

assign done = 0;

endmodule

module kernel_convolution_controlpath