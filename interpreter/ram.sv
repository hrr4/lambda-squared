`ifndef _ram_sv_
`define _ram_sv_

//`include "constants.svh"
`include "general.sv"

import general::*;

/***** MEMORY LAYOUT *****
 z: Free Space
 x: Marked for use
**************************/

module ram(
	   /*
	   // Flags
	   input logic re, // read enable
	   input logic wr, // write enable
	   // Data
	   input       bus_t d_out,
	   output      bus_t d_out
	   */
	   Bus bus
	    );

   // For now, we'll just use a sysverilog queue.
   byte 	       mem[$];

endmodule // ram

`endif