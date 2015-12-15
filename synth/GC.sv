typedef enum logic [1:0] {Zero=0, First=1, Second=2} mspass_t;

import lisp::*;



module GC(
	  // FETCH connections
	  input 		 clk,
	  // When en goes high, env_addr should already be on the line.
	  input 		 en,
	  input 		 env_addr,
	  input 		 max_addr, // This denotes the maximum used position
	  // RAM (passes through Fetch as master/slave) connections
	  input [WORD_SIZE-1:0]  data_in,
	  output 		 `ADDR_WIDTH addr,
	  output [WORD_SIZE-1:0] data_out,
	  output 		 rden,
	  output 		 wren
	  );

   logic `ADDR_WIDTH 		 addr_local = 0;
   logic [WORD_SIZE-1:0] 	 data_local = 0;
   logic 			 rden_local = 0;
   logic 			 wren_local = 0;
   logic [WORD_SIZE-1:0] 	 curr_env = 0;
   logic [WORD_SIZE-1:0] 	 first_env = 0;

   logic [WORD_SIZE-1:0] 	 kv_list = 0;
   
   mspass_t curr_state = Zero;
   mspass_t next_state = Zero;
   
   assign rden = rden_local;
   assign wren = wren_local;
   assign addr = addr_local; //(addr_local == '{13{1'bz}}) ? addr_local : ;
   assign data_out = data_local;
   
   // Combinational, Stop-the-World should allow this.
   always_comb begin
      if (en) begin
	 // TODO: This FSM will need to be converted to better logic, so we can actually read/write...Just a first pass though.
	 case (curr_state)
	   First:
	     begin
		logic [HWORD_SIZE-1:0] kv_pair;
		
		// If kv_list is 0, we're just beginning the algorithm.
		if (kv_list == 0) kv_list = cdr_data(curr_env);
	        
		kv_pair = car_data(kv_list);
		
		if (car_data(kv_pair) != NIL) begin // Don't know what NIL is yet.
		   wren_local = 1;
		   addr_local = cdr_data(kv_pair);
		   data_local = '{Mark, }; // How to implant data into Ram...might need some size output..

		   kv_pair = cdr_data(kv_list);
		end else
		  begin
		     kv_list = cdr_data(kv_list);
		     
		     if (car_data(kv_list) == NIL)
		       begin
			  // Try to traverse the environment stack.
			  logic [WORD_SIZE-1:0] next_env = car_data(curr_env);
			  
			  if (next_env != NIL) // won't compile
			    curr_env = next_env;
			  else begin
			     // We're out of environments, goto the next state.
			     next_state = Second;
			  end
		       end
		  end
	     end
	   
	   Second:
	     begin
		// Go through the entire set of memory, looking for sweep mem.
		logic [HWORD_SIZE-1:0] kv_pair;
		logic [WORD_SIZE-1:0]  key_data;
		
		// If kv_list is 0, we're just beginning the algorithm.
		if (kv_list == 0) kv_list = cdr_data(curr_env);
	        
		kv_pair = car_data(kv_list);

		key_data = car_data(kv_pair);
		
		if (key_data != NIL) begin // Don't know what NIL is yet.
		   if (kv_pair[WORD_SIZE-1] == Sweep) begin
		      // Write that memory as freed, traverse the tree and clear all the mem until a NIL.
		   end
		   /*
		   wren_local = 1;
		   addr_local = cdr_data(kv_pair);
		   data_local = '{Mark, }; // How to implant data into Ram...might need some size output..

		   kv_pair = cdr_data(kv_list);
		    */
		end else
		  begin
		     kv_list = cdr_data(kv_list);
		     
		     if (car_data(kv_list) == NIL)
		       begin
			  // Try to traverse the environment stack.
			  logic [WORD_SIZE-1:0] next_env = car_data(curr_env);
			  
			  if (next_env != NIL) // won't compile
			    curr_env = next_env;
			  else begin
			     // We're out of environments, goto the next state.
			     next_state = Second;
			  end
		       end
		  end
	     end

	   Zero:
	     begin
		// If we're in Idle state & we're enabled, it's time to begin collection.
		next_state = First;
		curr_env = env_addr;
		first_env = env_addr;
		
	     end
	 endcase
      end
      else
	begin
	   addr_local = 0;
//	   curr_state = Zero;
	   next_state = Zero;
	end // else: !if(en)

//      if (curr_state != next_state)
//	curr_state = next_state;
   end // always_comb

   always_ff @ (posedge next_state)
//     if (curr_state != next_state)
       curr_state <= next_state;

endmodule // GC
