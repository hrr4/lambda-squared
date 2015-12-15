
package lisp;
`define ADDR_WIDTH [VALUE_WIDTH-1:0]
   
   localparam TYPE_WIDTH = 3;
   localparam VALUE_WIDTH = 32;
   typedef logic [VALUE_WIDTH-1:0] addr_t;

   typedef enum logic [TYPE_WIDTH:0] 
		{
//		 Type_NIL = 'h0,
		 Type_Primitive,
		 Type_Cons,
		 Type_Symbol,
		 Type_Procedure,
		 Type_Number
		 } type_t;

   typedef struct packed {
      type_t t;
      addr_t data; // this needs reworked, maybe not, it should be whatever size of addressable mem we are using.
   } cell_t; // Half-word Cell

   typedef enum bit {Sweep = 0, Mark} gc_t;
   
   typedef struct packed {
      gc_t   gc; // Bit used for mark and sweep value.
      cell_t car;
      cell_t cdr;
   } obj_t;

   localparam WORD_SIZE = $bits(obj_t);
   localparam HWORD_SIZE = $bits(cell_t);

   localparam M9K_TYPE 1'd1;
   localparam RAM_TYPE 1'd0;
   
   // Don't need two different types for our memory...it should all be the same word size at least...
   typedef enum [WORD_SIZE-1:0] m9k_addr_t;
   //typedef enum [WORD_SIZE-1:0] ram_addr_t;

   function m9k_addr_t make_m9k_addr;
      make_m9k_addr[$left(make_m9k_addr)] = M9K_TYPE;
      for (int i = 1; i < $size(make_m9k_addr); ++i)
	make_m9k_addr[i] = 1'd0;
   endfunction //

   function ram_addr_t make_ram_addr;
      for (int i = 0; i < $size(make_ram_addr); ++i)
	make_ram_addr[i] = RAM_TYPE;
   endfunction //
   
   /*
    function addr_t car_data;
    input 	  addr_t c;
    
    car_data = c.car;
   endfunction
    
    function addr_t cdr_data;
    input 	  addr_t c;
    
    cdr_data = c.cdr;
   endfunction
    */
   
   function cell_t car;
      input 	  cons_t c;
      
      car = c.car;
   endfunction // car

   function cell_t cdr;
      input 	  cons_t c;

      cdr = c.cdr;
   endfunction // cdr
   
   localparam CONS_SIZE = $bits(cons_t);
   
   const cons_t MEM_FREE = '{Type_NIL, {CONS_SIZE{12'hAF}}};
   const cons_t MEM_USED = '{Type_NIL, {CONS_SIZE{12'hBE}}};

   localparam SYM_MAX = 64;
   typedef byte sym_t [SYM_MAX];
   
endpackage: lisp
