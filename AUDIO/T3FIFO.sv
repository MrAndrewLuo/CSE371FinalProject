module T3FIFO #(parameter SIZE=8, DATA=24) (clk, reset, write, read, wdata, rdata, full, empty);
   input  logic clk, reset, write, read;
   input  logic [DATA-1:0] wdata;
   output logic [DATA-1:0] rdata;	     
   output logic full, empty;
   		 logic [$clog2(SIZE)-1:0] readpt, writept, readpt1, writept1;
   		 logic [DATA-1:0] memz [0:SIZE-1];
			 logic flag;

	// Flag Signals
   assign empty = ~flag & (readpt == writept);
   assign full = flag & (readpt == writept);
   // Next Pointers
   assign readpt1 = ((readpt + 1) % SIZE == 0) ? '0 : readpt + 1;
   assign writept1 = ((writept + 1) % SIZE == 0) ? '0 : writept + 1;

   always_comb begin
      rdata = '0;
      if (read & ~empty & ~reset) rdata = memz[readpt];
   end

   integer i;
   always_ff @(posedge clk) begin
      if (reset) begin
			{readpt, writept, flag} <= '0;
         for (i=0; i<SIZE; i++) memz[i] <= '0;
      end else begin
			// Flagging
			if (read & ~write & (writept == readpt1)) flag <= 0;
			else if (write & ~read & (readpt == writept1)) flag <= 1;

			// Pointers
			if (read & ~empty) begin
				// rdata <= mem[readpt]; // non-FWFT
            readpt <= readpt1;
			end
			if ((write & ~full) || (write & read))  begin
				memz[writept] <= wdata;
            writept <= writept1;
			end
      end
   end
endmodule // FIFO

module T3FIFOTest ();
   logic clk, reset, write, read, full, empty;
   logic [15:0] wdata, rdata;

   T3FIFO #(10, 16) dut (.*);
   
   // Set up the clock.
   parameter CLOCK_PERIOD=20000; // 20ns = 50MHz
   initial begin
      clk <= 0;
      forever #(CLOCK_PERIOD/2) clk <= ~clk;
   end

   int i;
   initial begin
      {write, read, wdata} = '0;
      reset = 1; @(posedge clk);
      reset = 0; @(posedge clk);

      // write until full
      {read, write} = 2'b01;
      for (i = 0; i < 10; i++) begin
			wdata = i[15:0]; @(posedge clk);
      end

      // simultaneous read-write
      {read, write} = 2'b11;
      for (i = 10; i < 20; i++) begin
			wdata = i[15:0]; @(posedge clk);
      end

      // read until empty
      {read, write} = 2'b10;
      repeat (10) @(posedge clk);
      
      $stop;
   end
endmodule
  
