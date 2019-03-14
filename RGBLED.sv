// Controls LED lights depending on which filter is applied
module RGBLED (SW, color);
	input logic [4:0] SW;
	output logic [2:0] color;
	
   localparam RED = 3'b011;
   localparam GREEN = 3'b101; 
   localparam BLUE = 3'b110; 
   localparam YELLOW = 3'b001; 
   localparam CYAN = 3'b100; 
   localparam MAGENTA = 3'b010; 
   localparam WHITE = 3'b000; 
   localparam OFF = 3'b111;

	always_comb
      case(SW)
         5'b00000: 
            color = OFF;
         5'b00001: // Grayscale
            color = YELLOW;
         5'b00010: // Vertical Conv.
            color = CYAN; 
         5'b00100: // Horizontal Conv.
            color = MAGENTA;
         5'b01000:
            color = BLUE;
         5'b10000:
            color = GREEN;
         default: color = RED;
      endcase

endmodule