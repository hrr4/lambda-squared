import general::*;

// Fetch should control the op busy/done thing. Don't add it here....it's stupid.

module RAM(
	   input 		  `ADDR_WIDTH addr,
	   input 		  clk,
	   input 		  data,
	   input 		  rden,
	   input 		  wren,
	   output 		  mem_status_t status_out,
	   output [WORD_SIZE-1:0] q
	   );

   localparam max_sz = 128;

   obj_t [max_sz-1:0] mem = 0;
   mem_status_t status = mem_ok;
   logic [WORD_SIZE-1:0] 	  data_out;

   assign status_out = status;
   assign q = data_out;

   /*
   function mem_status_t addr_check;
      input 			  `ADDR_WIDTH addr_in;
      
      if (addr_in >= max_sz || addr_in < 0)
	addr_check <= mem_oob;
   endfunction
   */
   
   always_ff @ (posedge clk) begin
      data_out = z;
      status <= mem_ok;
      
      if (rden) begin
	 if (addr >= max_sz || addr_in < 0) begin
	    status <= mem_oob;
	    q <= mem[0]; // Returns whatever is at the first position. *Probably Nil*
	 end
	 else
	   q <= mem[addr];
      end
      else if (wren) begin
	 if (addr >= max_sz || addr_in < 0) begin
	    status <= mem_oob;
	 end
	 else
	   mem[addr] <= data;
      end
   end
   
endmodule // RAM

