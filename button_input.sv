module button_input (clk, reset, button, pressed);
	input clk, reset, button;
	
	// pressed – did we have a discrete button click?
	output reg pressed;
	
	// 0 = off, 1 = on
    reg ps;
    reg ns;
	
	// Next State logic
	always_comb
	begin
        ns = ~button;
		  pressed = ~ps & ~button;
	end
		
	// DFFs
	always_ff @(posedge clk)
		if (reset) begin
			ps <= 0;  
		end
		else begin
			ps <= ns;
		end
	
endmodule

module button_input_testbench();
	reg clk, reset, button, pressed;

	button_input dut (clk, reset, button, pressed);
	// Set up the clock.
	parameter CLOCK_PERIOD=100;
	initial clk=1;
	always begin
		#(CLOCK_PERIOD/2);
		clk = ~clk;
	end

	// Set up the inputs to the design. Each line is a clock cycle.
	initial begin
	   // check closed - closed 
		reset <= 1; button <= 1;	            
      @(posedge clk);
		reset <= 0;
      @(posedge clk);
      // test no one is moving
		reset <= 0;		    
      @(posedge clk);
      @(posedge clk);

      // check turn on
		reset <= 1;	            
      @(posedge clk);
		reset <= 0;
      @(posedge clk);
      // test no one is moving
		reset <= 0;	button <= 0;	    
      @(posedge clk);
      @(posedge clk);
		
      // check turn on only once
		reset <= 1;	            
      @(posedge clk);
		reset <= 0;
		@(posedge clk);
      // test no one is moving
		reset <= 0;	button <= 0;	    
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);

      // check turn on multipletimes
		reset <= 1;	            
      @(posedge clk);
		reset <= 0;
		@(posedge clk);
      // test no one is moving
		reset <= 0;	button <= 0;	    
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
		button <= 1;
      @(posedge clk);	
      @(posedge clk);		
		button <= 0;	
      @(posedge clk);	
      @(posedge clk);		

		$stop; // End the simulation.
	end
endmodule
