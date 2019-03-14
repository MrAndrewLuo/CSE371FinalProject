module T3Filter #(parameter N = 5) (clk, reset, en, rd_data, wr_data, read, write);
	input  logic clk, reset, en;
   input  logic signed [23:0] rd_data;
   output logic read, write;
   output logic signed [23:0] wr_data;
   logic  signed [23:0] sum, dataIn, dataOut;
   logic  readFIFO, writeFIFO, full, empty;

   assign dataIn = rd_data >>> N;
   assign readFIFO = en & full;
   assign writeFIFO = en;

   assign read = writeFIFO;
   assign write = readFIFO;
   
	T3FIFO #(2**N, 24) fifo  (.clk, .reset, .write(writeFIFO), .read(readFIFO), .wdata(dataIn), .rdata(dataOut), .full, .empty);

   assign wr_data = sum;
	always_ff @(posedge clk) begin
      if (reset) sum <= '0;
      else if (en) sum <= sum + dataIn - dataOut;
      else sum <= sum;
   end 
endmodule

module T3FilterTest ();
   logic clk, reset, en, read, write;
   logic signed [23:0] rd_data, wr_data;

   initial begin
      clk <= 0;
      forever #(10) clk <= ~clk;
   end

   T3Filter #(3) dut (.*);
   integer i;
   initial begin
      {en, rd_data} <= '0;
      reset <= 1; @(posedge clk);
      reset <= 0; @(posedge clk);
      
      rd_data <= 24'd8;
      for (i = 0; i < 10; i++) begin
         en <= 1'b1; @(posedge clk);   
         en <= 1'b0; @(posedge clk);   
      end

      rd_data <= 24'd0;
      for (i = 0; i < 10; i++) begin
         en <= 1'b1; @(posedge clk);   
         en <= 1'b0; @(posedge clk);   
      end
      $stop; 
   end
endmodule