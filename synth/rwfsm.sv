/********************
   Read & Write FSM
 - Generic interface to read and write from Fetch/RAM.
 - Instantiate in any module that connects to Fetch/RAM.
 
   Using:
 * Write
   - wren_in, addr_in, data_in: Must be set.
   - rden_out, wren_out, addr_out, data_out: Wired to RAM interface. (this assumes the memory takes a rden & wren)
 
 * Read
   - 
 
 *******************/

typedef enum logic [1:0] {idle = 0, write, read} state_t;

import general::*;
import lisp::*;

module rwfsm(
	     input 		    clk,
	     input 		    rden_in,
	     input 		    wren_in,
	     input 		    `ADDR_WIDTH addr_in,
	     input [WORD_SIZE-1:0]  data_in,
	     input 		    mem_ret_in, // Memory status
	     output 		    rden_out,
	     output 		    wren_out,
	     output 		    op_out,
	     output 		    `ADDR_WIDTH addr_out,
	     output [WORD_SIZE-1:0] data_out
	     );
   
   state_t 	    curr_state = idle;
   state_t 	    next_state = idle;
   
   logic 			    rden;
   logic 			    wren;
   logic 			    mem_ret;
   
   logic 			    rden_lcl_out = 0;
   logic 			    wren_lcl_out = 0;
   logic [WORD_SIZE-1:0] 	    data_lcl = 0;
   
   addr_t addr_lcl = 0;

   op_t op_status = done;
   
   always @ (rden_in) rden = rden_in;
   always @ (wren_in) wren = wren_in;
   always @ (mem_ret_in) mem_ret = mem_ret_in;

   assign rden_out = rden_lcl_out;
   assign wren_out = wren_lcl_out;
   assign op_out = op_status;
   assign addr_out = addr_lcl;
   assign data_out = data_lcl;
   
   always_ff @ (posedge clk) begin
      if ((rden_lcl_out || wren_lcl_out) && op_status == done) begin // Reset if the operation is complete.
	 next_state <= idle;
	 rden_lcl_out <= 0;
	 wren_lcl_out <= 0;
      end
      else begin
	 // Set everything to some default state, 
	 // so we can modify them later and not worry about synthesis.
	 data_lcl <= 0;
	 addr_lcl <= 0;
	 op_status <= busy;
	 rden_lcl_out <= 0;
	 wren_lcl_out <= 0;
	 
	 case (curr_state) begin
	    idle: begin
	       op_status <= done;
	       rden_lcl_out <= 0;
	       wren_lcl_out <= 0;
	       
	       if (rden) next_state <= read;
	       else if (wren) next_state <= write;
	       else next_state <= idle;
	    end
	   
	   write: begin
	      // Set busy flag
	      op_status <= busy;

	      // Set write enable out high.
	      wren_lcl_out <= 1;

	      // Output the address to write to.
	      addr_lcl <= addr_in;

	      // Output the data to write.
	      data_lcl <= data_out;

	      // Check for our operation to be finished.
	      if (mem_ret == done) begin
		 next_state <= idle;
		 op_status <= done;
	      end
	   end
	   
	   read: begin
	      // Set busy flag
	      op_status <= busy;

	      // Set read enable out high.
	      rden_lcl_out <= 1;
	      
	      // Output the address to read from.
	      addr_lcl <= addr_in;
	      
	      // We need to wait until data has gone high.
	      if (data_in != 0 || mem_ret == done) begin 
		 // We have new data.
		 data_lcl <= data_in;
		 next_state <= idle;
		 op_status <= done; // Setting it here, so we can actually hit the reset conditional!
	      end
	   end
	 end
      end
   end

   always_comb @ (next_state) curr_state = next_state;

endmodule // rwfsm
