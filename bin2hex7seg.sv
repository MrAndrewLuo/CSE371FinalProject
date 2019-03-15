module bin2hex7seg(binary, hex);
	localparam H_ = ~7'b0000000; // EMPTY
	localparam H0 = ~7'b0111111; // 0
	localparam H1 = ~7'b0000110; // 1
	localparam H2 = ~7'b1011011; // 2
	localparam H3 = ~7'b1001111; // 3
	localparam H4 = ~7'b1100110; // 4
	localparam H5 = ~7'b1101101; // 5
	localparam H6 = ~7'b1111101; // 6
	localparam H7 = ~7'b0000111; // 7
	localparam H8 = ~7'b1111111; // 8
	localparam H9 = ~7'b1101111; // 9
	
	localparam Ha = 7'b0001000; // A
   localparam Hb = 7'b0000011; // B
	localparam Hc = 7'b1000110; // C
	localparam Hd = 7'b0100001; // D
	localparam He = 7'b0000110; // E
   localparam Hf = 7'b0001110; // F
	
	output logic [6:0] hex;
	input [3:0] binary; 
	
	always_comb
		case (binary)
			0:  hex = H0;
			1:  hex = H1;
			2:  hex = H2;
			3:  hex = H3;
			4:  hex = H4;
			5:  hex = H5;
			6:  hex = H6;
			7:  hex = H7;
			8:  hex = H8;
			9:  hex = H9;
			10: hex = Ha;
			11: hex = Hb;
			12: hex = Hc;
			13: hex = Hd;
			14: hex = He;
			15: hex = Hf;
			default: hex = H_;
		endcase
endmodule