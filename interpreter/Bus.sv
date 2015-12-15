`ifndef _bus_sv
 `define _bus_sv_

`include "general.sv"
//`include "constants.svh"

// This is good idea
interface Bus;
   logic [general::WORD_SIZE:0] 	addr;
   logic [general::WORD_SIZE:0] 	data;
   logic 			RW;
endinterface // Bus

`endif