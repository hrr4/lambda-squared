// Somehow look at 



import lisp::*;

module Fetch(
	     // Decoder interface
	     input 		    dec_clk,
	     input 		    dec_rden,
	     input 		    dec_wren,
	     input 		    `ADDR_WIDTH dec_addr_in,
	     input [WORD_SIZE-1:0]  dec_data_in,
	     output 		    dec_oen,
	     output [WORD_SIZE-1:0] dec_data_out,
	     
	     // RAM interface
	     input [WORD_SIZE-1:0]  ram_data_in,
	     input 		    ram_mem_ret,
	     output 		    `ADDR_WIDTH ram_addr_out,
	     output 		    ram_rden,
	     output 		    ram_wren,
	     output [WORD_SIZE-1:0] ram_data_out,

	     // GC interface
	     
	     );

   typedef enum logic [2:0] 
		{
		 Idle,
		 Read,
		 Write,
		 GC,
		 Timeout
		 } state_t;

   state_t curr_state = Idle;
   state_t next_state = Idle;
   
   // Here comes the giant FSM.
   always_ff @ (posedge dec_clk) begin
      case (curr_state)
        Read: begin
	   ram_rden <= 1;
	   ram_addr_out <= dec_addr_in;
	   ram_data_out <= dec_data_in;

	   // Wait for ram status and data to come in.
	   if (
	end

	Write: begin
	   
	end

	GC: begin
	       

	end

	Idle: begin
	   if (dec_rden) next_state = Read;
	   if (dec_wren) next_state = Write;
	   
	end

	Timeout: begin

	end
	
      endcase
	       
   end
	       
   always_comb @ (next_state) curr_state = next_state;
   
endmodule
