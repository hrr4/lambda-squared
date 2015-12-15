package general;
   typedef enum bit [2:0] 
		{
		 err_none,
		 err_mem_full,
		 err_mem_used
		 } err_t;

   typedef enum bit [2:0]
		{
		 //status_mem_found
		 status_ok,
		 status_err,
		 status_ret,
		 status_eof
		 } status_t;
   
   localparam TYPE_WIDTH = 5;
   localparam VALUE_WIDTH = 16;
   localparam WORD_SIZE = TYPE_WIDTH + VALUE_WIDTH * 2; // Cell * 2
   localparam MEM_WIDTH = 256;

   localparam UNINIT = {VALUE_WIDTH{3'b00}};
   

   // File I/O
   localparam EOF = 9'h1ff;
   localparam ERR = -2;
   
   localparam MEM_ERR = 32'bz;
   
   // Memory type *probably temporary until RAM gets used.*
   typedef logic [VALUE_WIDTH-1:0] addr_t;
   typedef integer file_t;
   typedef integer stat_t;
   typedef reg [8:0] char_t;

   // Use this for error codes or something
   //typedef reg [2:0] ret_t;
   
   typedef logic [WORD_SIZE:0] bus_t;
   
   // When using interfaces, must be instantiated:
   // Bus bus();
   
endpackage: general
   
