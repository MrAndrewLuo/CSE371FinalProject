/*
Taken from the review section: credit where credit is due :).

Modified to fit specifications
*/

module fifo 
		  #(parameter WIDTH = 24, N = 7) 
		  (
	     input logic clk, rst, write, read,
	     input logic [WIDTH - 1:0] wdata,

	     output logic [WIDTH - 1:0] rdata,	     
	     output logic full, empty, almost_full
	     );
   logic [WIDTH - 1:0] mem [2 ** N - 1:0];
   logic        flag;
	
   logic [N - 1:0]  readptr, writeptr, rpp1, wpp1;
	logic [WIDTH - 1:0] rdata_buff;

   assign rpp1 = readptr + 1;
   assign wpp1 = writeptr + 1;
   
   assign empty = ~flag & (readptr == writeptr);
   assign full = flag & (readptr == writeptr);
	assign almost_full = flag & (wpp1 == readptr);
   
   always_ff @(posedge clk) begin
      if (rst) begin
			{readptr, writeptr, flag} <= '0;
      end 
		else begin
			// flag handling
			if (read & ~write) flag <= 0; // will be empty
			else if (write & ~read) flag <= 1; // will be full
			else flag <= flag;
			 
			// pointer handling
			if (read) readptr <= rpp1;
			else readptr <= readptr;

			if (write) writeptr <= wpp1;
			else writeptr <= writeptr;
      end

      if (write) mem[writeptr] <= wdata;
		
		//rdata_buff <= mem[readptr];
      if (read) rdata <= mem[readptr]; // standard non-FWFT fifo read port
		else rdata <= 0; // compatability with test benches
   end
endmodule // FIFO

module FIFO_testbench ();
	localparam WIDTH = 24;
	localparam N = 7;

   logic clk, rst, write, read, full, empty, almost_full;
   logic [WIDTH - 1:0] wdata, rdata;

   fifo dut (.*);
   
   // Set up the clock.
   parameter CLOCK_PERIOD=20000; // 20ns = 50MHz
   initial begin
      clk <= 1;
      forever #(CLOCK_PERIOD/2) clk <= ~clk;
   end

   int i;
   initial begin
      {write, read, wdata} = '0;
      rst = 1;
      @(posedge clk);
      rst = 0;
      @(posedge clk);

      // initial 20 items
      {read, write} = 2'b01;
      for (i = 0; i < 20; i++) begin
		 wdata = i[WIDTH - 1:0];
		 @(posedge clk);
      end

      // simultaneous read-write
      {read, write} = 2'b11;
      for (i = 0; i < 20; i++) begin
		 wdata = i[WIDTH - 1:0];
		 @(posedge clk);
      end

      // write until full
      {read, write} = 2'b01;
      for (i = 0; i < 2 ** N; i++) begin
		 wdata = i[WIDTH - 1:0];
		 @(posedge clk);
      end

      // read until empty
      {read, write} = 2'b10;
      repeat (2 ** N + 20) @(posedge clk);
      
      $stop;
   end
endmodule
  
