`include "constants.svh"
`include "general.sv"

package lisp;
   typedef enum bit [general::TYPE_WIDTH:0] 
		{
		 Type_NIL = 'h0,
		 //Type_T,
		 Type_Primitive,
		 Type_Cons,
		 Type_Symbol,
		 Type_Procedure,
		 Type_Number
		 } type_t;

   typedef struct packed {
      type_t t;
      general::addr_t data; // this needs reworked, maybe not, it should be whatever size of addressable mem we are using.
   } cell_t; // Half-word Cell
   
   typedef struct packed {
      cell_t car;
      cell_t cdr;
   } cons_t;
   
   function cell_t car;
      input 	  cons_t c;

      car = c.car;
   endfunction // car

   function cell_t cdr;
      input 	  cons_t c;

      cdr = c.cdr;
   endfunction // car
   
   localparam CONS_SIZE = $bits(cons_t);
   
   const cons_t MEM_FREE = '{Type_NIL, {CONS_SIZE{12'hAF}}};
   const cons_t MEM_USED = '{Type_NIL, {CONS_SIZE{12'hBE}}};

   localparam SYM_MAX = 64;
   typedef byte sym_t [SYM_MAX];
   
endpackage: lisp

