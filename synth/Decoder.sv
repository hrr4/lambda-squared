
import lisp::*;

module Decoder(
	       input 		      comp_clk,

	       input 		      fch_oen,
	       input [WORD_SIZE-1:0]  fch_data_in,

	       output 		      fch_clk,
	       output 		      fch_rden,
	       output 		      fch_wren,
	       output 		      `ADDR_WIDTH fch_addr_out,
	       output [WORD_SIZE-1:0] fch_data_out
	       );

   typedef enum logic [2:0]
		{
		 idle,
		 read,
		 eval,
		 print,
		 } state_t;

   typedef enum logic [2:0]
		{
		 sub_idle,
		 sub_read,
		 sub_write
		 } substate_t;

   state_t curr_state = idle;
   state_t next_state = idle;
   substate_t curr_substate = sub_idle;
   substate_t next_substate = sub_idle;
   
   logic [WORD_SIZE-1:0] fch_addr_lcl = 0;
   logic [WORD_SIZE-1:0] fch_data_lcl = 0;
   
   assign fch_clk = comp_clk;

   always_ff @ (posedge comp_clk) begin
      fch_rden <= 0;
      fch_wren <= 0;
      
      case (curr_substate)
	sub_read:
	  begin
	     fch_rden <= 1;
	     fch_wren <= 0;
	     
	     if (fch_oen && fch_data_in) begin
		fch_data_lcl = fch_data_in;

		curr_substate = sub_idle;
	     end
	  end

	sub_write:
	  begin
	     fch_rden <= 0;
	     fch_wren <= 1;
	     
	  end
	
	sub_idle:
	  begin
	     
	  end
      endcase // case (curr_substate)
      
      case (curr_state)
	read:
	  begin
	     if (fch_data_lcl != 0) begin
		// We have data to do something with...
		
		// Let's look at the MSB....
		case (fch_data_lcl[$left(fch_data_lcl)])
		  RAM_TYPE:
		    begin
		       
		    end
		  M9K_TYPE:
		    begin
		       
		    end 
		endcase
	     end else 
		curr_substate = sub_read;
	  end
	
	eval:
	  begin
	     
	  end
	
	print:
	  begin
	     
	  end
	
	idle:
	  begin
	     
	  end
	
      endcase // case (curr_state)

      curr_state <= next_state;
      curr_substate <= next_substate;
   end

endmodule
