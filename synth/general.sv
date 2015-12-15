package general;
/*
   typedef enum logic [2:0] 
		{
		 err_none,
		 err_mem_full,
		 err_mem_used
		 } err_t;
  */
 
   typedef enum logic [2:0]
		{
		 //status_mem_found
		 status_busy,
		 status_ok,
		 status_err,
		 status_ret,
		 status_eof
		 } status_t;

   typedef enum logic {busy, done} op_t;
   
   localparam UNINIT = 0;
   
   // File I/O
   localparam EOF = 9'h1ff;
   localparam ERR = -2;
   
   localparam MEM_ERR = 32'bz;
   
   // Memory type *probably temporary until RAM gets used.*
   typedef integer file_t;
   typedef reg [8:0] char_t;

   typedef enum logic [1:0]
	      {
	       mem_null,
	       mem_ok,
	       mem_full,
	       mem_oob // Out of bounds
	       } mem_status_t;
   
   /*
   typedef enum logic [1:0] {
			     Imp = 2'bz,
			     Rd = 2'b0,
			     Wr = 2'b1
			     } wire_t;
    */
   
   // Use this for error codes or something
   //typedef reg [2:0] ret_t;
   
   //typedef logic [WORD_SIZE:0] 	   bus_t;
   
   // When using interfaces, must be instantiated:
   // Bus bus();
   
endpackage: general
   
