// Lisp interpreter in System Verilog

/***** IDEAS *****
 - Every atomic value stores its size as the first cons cell in the chain.
 - FETCH can pull up to word size CONS cells.
 - Virtual addressing (Double indirection). This will help with garbage collection and pointer values.
 - Might continuously update the free store position variable. That way RAM can keep track of where the first position in
   memory is (since they're only CONS cells).
 - Need a scratch register or stack or something for the symbol string thing.
   * Added - Remember, on every new write, reinitialize it to 'z' values, so we can tell whats what.
 - In our lisp, Numbers seem equivalent to Symbols...
 ****************/

//`include "constants.svh"
`include "general.sv"
`include "lisp.sv"

// Imports
import general::*;
import lisp::*;

// Registers
//addr_t VAL, EXP, LINK, ENV, ARG;
// Constants that need definition through the interpreter.
addr_t nil, t, root_env, all_symbols;
sym_t scratch;

// Primitive Symbols
addr_t s_t, s_lambda, s_quote, s_setq, s_define, s_if;

reg [7:0] scratch_sz = 0; // Start at the MSB

// Data store
// Memory of conses (It's our only memory!)
cons_t mem [MEM_WIDTH-1] ;

shortint mem_pos; // This is global for now....

integer free_pos; // Denotes where the free store begins

/* Scratch Functions */
// Shift the scratch buffer. Either positively or negatively.
function void scratch_shift;
   input integer amt;
   
   if (amt > 0) begin
     automatic integer i;
      
      for (i = 0; i < amt; i = i + 1) begin
	 scratch[(SYM_MAX - 1) - i +: 1] = scratch[(scratch_sz - 1) - i -: 1] ;
	 scratch[(scratch_sz - 1) - i] = 0;
      end
   end
   else if (amt < 0) begin /* Don't know if this'll work, probably won't use it though, just for completeness I guess. */
      automatic integer i;
      
      for (i = amt; i >= 0; i = i - 1) begin
	 scratch[(SYM_MAX - 1) - i +: 1] = scratch[(scratch_sz - 1) - i -: 1] ;
	 scratch[(scratch_sz - 1) - i] = 0;
      end
   end
endfunction // scratch_shift

// Will take some data and write it (correctly) to the scratch.
function sym_t ScratchWrite;
   input addr_t sym_addr;
   
   // Reinitialize Scratch.
   automatic integer i;
   for (i = 0; i < scratch_sz; i = i + 1) begin
     scratch[i] = 0;
   end
   
   i = 0;
   
   while (car_type(sym_addr) != Type_NIL && i < SYM_MAX) begin
      scratch[i++] = car_data(sym_addr);
      sym_addr = mem[cdr_data(sym_addr)];
   end

   // Shift the scratch by the amount we wrote in.
   scratch_shift(i);

   return scratch;
endfunction

/*
function sym_t ScratchRead;
  
  
endfunction
*/

/* Memory Functions */

function void InitMem;
   integer i;

   for (i = 0; i < MEM_WIDTH; i = i + 1)
     mem[i] = MEM_FREE;
   
endfunction

// ReqMem - Allows external entities to request memory.
// It will always return an address (virtual or not) to the position in memory the object begins.
// Only thing it does right now is tries to mark mem with x's
// For now, only request 1 cell.
// Since we know we're requesting cons cells, we should link the cells together HERE, not later.
function addr_t ReqMem;
   input byte sz; // Size requested (# of CONS cells)

   automatic byte amt_found = 0;
   automatic err_t mem_status = err_none;
   automatic integer j = free_pos;

   automatic addr_t prev_cell = 0;
   automatic addr_t first_cell = 0;
   
   integer    i;
   // Make sure we find all cons cells
   for (i = 0; i < sz; i = i + 1) begin
      mem_status = err_mem_full;
      
      // Traverse the free store, find next available spot.
      for (; j < MEM_WIDTH; j = j + 1) begin
	 automatic cons_t cons = mem[j];

	 if (cons == MEM_FREE) begin
	    cons.car = MEM_USED;

	    if (prev_cell != 0) begin
	       cons.cdr.data = prev_cell;
	    end

	    prev_cell = j;
	    mem_status = err_none;
	    break;
	 end // if (cons == MEM_FREE)
      end // for (; j < MEM_WIDTH; j = j + 1)
      
      if (mem_status != err_none) // Something went wrong, we're done.
	break;
      
   end // for (i = 0; i < sz; i = i + 1)
   
   ReqMem = (mem_status == err_none) ? prev_cell : MEM_ERR;
endfunction

/* Helper functions */
// Checks if digit
function logic isdigit;
   input char_t c;
   
   isdigit = (c > 47 && c < 58);
endfunction

// Checks if alphanumeric
function logic isalpha;
   input char_t c;
   
   isalpha = ((c > 64 && c < 91) // Capitals
	      || (c > 96 && c < 123)); // Lowercase
endfunction 

// Checks if whitespace (No EOF)
function logic iswhitespace;
   input char_t c;

   iswhitespace = (c == " " || c == "\n" || c == "\r" || c == "\t");
endfunction // interpreter

// Reads next character in memory.
function char_t nextc;
   //input addr_t pos;
   nextc = mem[mem_pos++]; //pos];
endfunction // nextc

function void putbackc;
	mem_pos = mem_pos-1;
endfunction 

/* Lisp builder functions */
// Creates a cons cell.
// Calls out to memory functions to retrieve new memory.
function addr_t cons;
   input addr_t car;
   input addr_t cdr;
   
   automatic addr_t addr = ReqMem(1); // # of cons cells we want
   
   if (addr !== MEM_ERR) begin
      // Map the CONS cell to memory directly here.
      mem[addr].car = '{Type_Cons, car};
      mem[addr].cdr.data = cdr;
      
      cons = addr;
   end
   else
     cons = MEM_ERR;
endfunction // Cons

function general::addr_t car_data;
   input 	  general::addr_t addr;
   
   car_data = mem[addr].car.data;
endfunction // car

function general::addr_t cdr_data;
   input 	  general::addr_t addr;

   cdr_data = mem[addr].cdr.data;
endfunction // cdr

function general::addr_t car_type;
   input 	  general::addr_t addr;

   car_type = mem[addr].car.t;
endfunction

function general::addr_t cdr_type;
   input 	  general::addr_t addr;

   cdr_type = mem[addr].cdr.t;
endfunction


// Performs symbol lookup within the environment.
// This will be nasty O()-wise. {At least n^2 for now.}
// A way to fix this a bit in the future might be to store the symbols alphabetically, so we could use a faster matching algorithm.
// Environment = ((key . value) ... )
function addr_t assoc;
  input addr_t env;
  input addr_t sym;
 
   // Traverse the outer list.
   while (mem[env].car.t != Type_NIL) begin
      // Skip the first cell, it'll be a Cons.
      automatic cons_t inner_env = mem[cdr_data(mem[car_data(env)])];
      
      while (car(inner_env).t != Type_NIL) begin
	 automatic addr_t sym_temp = sym;
	 
	 if (car(inner_env).data == car(mem[sym_temp]).data) begin
	    inner_env = mem[cdr(inner_env).data];
	    sym_temp = cdr_data(sym_temp);

	    // For now, do a nasty check to see if both the symbol and current key we're looking at have nil as next cons. If we match, we've hit the end of the symbol and (should be) a match. 
	    if (cdr(inner_env).data == nil && cdr(sym_temp).data == nil)
	      return cdr(inner_env).data;
	 end
	 else begin // Didn't match.
	    sym_temp = sym;
	    break;
	 end
      end
      
      env = cdr_data(env);
   end // while (mem[env].car.t != Type_NIL)
   
   assoc = nil;
endfunction // Assoc


/* Lisp Symbol functions */
function addr_t Object;
   input sym_t sym;
   input type_t t;
   
   // Run through the string, building cons cells for each character and linking to the next cell.
   // Keep adding characters to the string list, until we hit whitespace. Upon whitespace, we should intern the symbol.
   // Return the first cell of the symbol...
   begin
      // Find the first byte of the symbol's actual string. (Chances are, its closer to the LSB than the MSB.)
      automatic integer i, pos;
      automatic addr_t prev_addr = UNINIT;
      automatic addr_t first_addr = UNINIT;
      automatic addr_t addr;
      
      // Find the first position of the symbol in the scratch
      for (i = SYM_MAX-1; i >= 0; i = i - 1) begin
         if (sym[i] == 0) begin
            i = i + 1;
	    pos = i;
            break;
         end
      end
      
      for (; i < SYM_MAX; i = i + 1) begin
         addr = ReqMem(1);
        
	 if (addr !== MEM_ERR) begin
	    if (pos == i) first_addr = addr;
	    // Link the previous cdr to the new address
	    if (prev_addr != UNINIT)
	      mem[prev_addr].cdr.data = addr;
	    
	    mem[addr].car.t = t;
	    mem[addr].car.data = sym[i];
	    
	    prev_addr = addr;
	 end
	 else
	   break;
      end
      
      // Make sure we point to a nil at the end of the symbol.
      mem[addr].cdr.data = nil;
      
      Object = first_addr;
   end
endfunction

function isnil;
   input addr_t p;
   
   isnil = (car_type(p) == Type_NIL);
endfunction // isnil

// Symbol comparison (similar to strcmp).
// Compares value at address to a byte 'char'.
// Will run the length of sym1 (until it hits nil).
// Return: 1 == match, 0 == no match.
function bit sym_cmp;
   input cons_t sym1;
   input sym_t sym2;
   
   begin
      automatic integer i = 0;
      automatic logic ret = 0;
      
      while (sym1.car.t != Type_NIL) begin
	 // Compare the value (car vs character in symbol)
	 if (sym1.car.data != sym2[i])
	   return 0;
	 
	 // TODO: Some bounds checking. What happens when sym1 is nil, but sym2 isn't. Vice-Versa?
         sym1 = sym1.cdr.data;
	 i = i + 1;
      end
      
      return 1;
   end
endfunction

function addr_t findSymbol;
   input sym_t sym_in;
   
   begin
      automatic addr_t sym = all_symbols;
      
      while (!isnil(sym)) begin
         automatic bit res = sym_cmp(mem[sym], sym_in);
	 
         if (res == 1)
           findSymbol = sym;
         
         sym = mem[sym].cdr.data;
      end
      
      findSymbol = nil;
   end
endfunction

function addr_t intern;
   input sym_t sym_in;

   begin
      automatic addr_t sym_cons = findSymbol(sym_in);
      
      if (!isnil(sym_cons))
	intern = mem[sym_cons].car;
      else begin
         automatic addr_t new_sym = Object(sym_in, Type_Symbol);
	 
	 // We didn't find the symbol, so we need to insert it into the symbol list.
	 all_symbols = cons(new_sym, all_symbols);
	 intern = new_sym;
      end
   end   
endfunction

// Reads a number from memory until a non-number.
// As we read, increase the decimal position (* 10) and add the actual value to a running count (convert from ascii).
function void ReadNumber;
   input char_t c_in;
   
   begin
      automatic char_t c = c_in;
      
      automatic integer i;
      for (i = 0; i < scratch_sz; ++i)
        scratch[i] = 0;
      
      while (isdigit(c)) begin //!iswhitespace(c) || ")") // Run until the end of the phrase.
	 scratch[scratch_sz++] = c;
	 c = nextc();
      end
      
      --mem_pos;
   end
endfunction

// ReadSymbol - Reads until whitespace, or invalid char.
// This will 'intern' a string. Symbols with the same name point to the same position in memory (weak references). This is also referred to as 'interning'.
// If the symbol exists, the address to it will be returned, else it'll create a new symbol (in a cell) and return an address to that.
function void ReadSymbol;
  // input cons_t env;
   input char_t c_in;

   begin
      automatic char_t c = c_in;
      automatic integer i;
      
      for (i = 0; i < scratch_sz; ++i)
        scratch[i] = 0;
        
      while (isalpha(c)) begin // Run until the end of the phrase.
	 scratch[scratch_sz++] = c;
	 c = nextc();
      end
      
      --mem_pos;
   end
   
endfunction // interpreter


function automatic addr_t ReadList;
   input cons_t env;

   char_t c = nextc();
   addr_t obj;
   
   if (c == ")") return nil;
   if (c == ".") begin
      obj = Read(env);
      if (nextc() == ")") return nil;

      return obj;
   end
   
   putbackc();
   obj = Read(env);
   
   return cons(obj, ReadList(env));
endfunction // interpreter


	  /*
function 
	   */

// ReadQuote - Everything after the quote will be returned as a literal string.
function addr_t ReadQuote;
   input cons_t env;

   ReadQuote = cons(s_quote, cons(Read(env), nil));
endfunction // ReadQuote

/***** CREATE FUNCTIONS *****/

// MakeNumber - Numbers are kind of just symbols in this Lisp...
function addr_t MakeNumber;
   scratch_shift(scratch_sz);
   
   MakeNumber = Object(scratch, Type_Number);
   
endfunction // MakeNumber

// MakeSymbol - Creates a symbol from whatever is in the scratch register.

function addr_t MakeSymbol; 
   scratch_shift(scratch_sz);

   MakeSymbol = intern(scratch);
endfunction // MakeSymbol

// This will handle the scratch shifting as well as the printing.
function void PrintScratch;
   automatic integer i;
   
   scratch_shift(scratch_sz);
   for (i = scratch_sz; i >= 0; i = i - 1)
     $write("%s", scratch[SYM_MAX-i]);
   
endfunction // PrintScratch

// Print whatever object we receive
function status_t Print;
   input addr_t obj;

   automatic status_t ret = status_ok;

   scratch_sz = 0;
   
   case(car_type(obj))
      Type_Number: begin
	 // Print values, traverse cdrs
	 while (car_type(obj)/*mem[obj].car.t*/ != Type_NIL) begin
	    scratch[scratch_sz++] = car_data(obj); //mem[obj].car.data;
	    obj = cdr_data(obj); //mem[obj].cdr.data;
	 end
	 
	 PrintScratch();
	 
      end // case: Type_Number
      
      Type_Symbol: begin
	 if (car_type(obj)/*mem[obj].car.t*/ == Type_NIL) begin
	    // Nil = Empty List "()"
	    scratch[SYM_MAX-1-scratch_sz++] = ")";
	    scratch[SYM_MAX-1-scratch_sz++] = "(";
	 end
	 else begin
            // Print values, traverse cdrs
	    while (car_type(obj) != Type_NIL) begin
	       scratch[scratch_sz++] = car_data(obj); //mem[obj].car.data;
	       obj = cdr_data(obj); //mem[obj].cdr.data;
	    end
	 end
	 
	 PrintScratch();
      end // case: Type_Symbol
      
      Type_Procedure: $display("#<FUNC>");
      Type_Primitive: $display("#<PRIM>");
      
      Type_NIL: ret = status_ret;
     
   endcase // case (mem[obj].car.t)
   
   Print = ret;
endfunction // Print

function addr_t evalis;
   input addr_t env;
   input addr_t exps;

   if (exps == nil) return nil;

   return cons(Eval(env, car_data(exps)),
	       evalis(env, cdr_data(exps)));
endfunction

function addr_t apply;
   input addr_t env;
   input addr_t proc;
   input addr_t vals;
/*
   if (car_type(proc ) == Type_Primitive)
     return 
*/
 endfunction 

function automatic addr_t Eval;
   input addr_t env;
   input addr_t obj;

   if (obj == nil) return nil;
   
   // Switch on the object's type.
   case (car_type(obj)) //mem[obj].car.t)
     Type_Number: return obj;
     Type_Symbol: begin
	automatic addr_t val = assoc(env, obj);
	
	if (val == nil) $display("Symbol unbounded");
	return cdr_data(val); //mem[val].cdr.data;
     end
     Type_Procedure: return obj;
     Type_Primitive: return obj;
     // This will get ridiculously messy. We have to control what happens to the primitives here.
     Type_Cons: begin
	automatic sym_t sym = ScratchWrite(car_data(obj));
	
	case (findSymbol(sym))
	  s_quote: 
	    return car_data(cdr_data(obj));
	  s_setq: begin
	     addr_t pair = assoc(car_data(cdr_data(obj)), env);
	     addr_t val = Eval(car_data(cdr_data(cdr_data(obj))), env);

	     mem[pair].cdr.data = val;
	     return val;
	  end

	  default:
	    return apply(env, Eval(env, car_data(obj)), evalis(env, cdr_data(obj)));
	endcase
     end // case (obj)
   endcase
endfunction // Eval

function addr_t progn;
   input addr_t env;
   input addr_t exps;

   if (exps == nil) return nil;
   
   forever begin
      if (cdr_data(exps) == nil)
	return Eval(env, car_data(exps));
      
      Eval(env, car_data(exps));
      exps = cdr_data(exps);
   end
endfunction

// Builds values as each character is read.
// When we end a phrase (whitespace or ")"), we need to throw this thing onto the environment (and/or) evaluate!
function automatic addr_t Read;
   input cons_t env;
   
   begin
      addr_t prev_addr;
      automatic status_t ret = status_ok;

      while (ret == status_ok) begin
	 automatic char_t c = nextc();
	 
	 case (c)
	   "(": prev_addr = ReadList(env); // Start a List
//	   ")": ret = status_ret; //We'll just do this so the while loop will end.
	   "\'": prev_addr = ReadQuote(env); // Quote
	   default: 
	     begin
		if (isdigit(c)) begin
		   ReadNumber(c);
		   //Read = MakeNumber();
		   
		   prev_addr = MakeNumber(); // A numeral
		end
		else if(isalpha(c)) begin // A symbol (TODO: Add non-alphanumeric characters!)
		   ReadSymbol(c);
		   //Read = MakeSymbol();
		   
		   prev_addr = MakeSymbol(); // Should read from scratch.
		   
		end
	        else if(c == EOF) ret = status_eof; // EOF
		else begin
		   // Let's try putting the char back...
		   putbackc();
		   ret = status_ret;
		end
	     end
	 endcase // case (c)
      end // while (ret != status_)

      Read = prev_addr;
   end
endfunction

function file_t DumpFile;
   input string file_string;
   
   begin
      char_t c;
      automatic int  i = free_pos;
      
      automatic file_t fd = $fopen(file_string, "r");
      
      if (!fd) $display("Could not open %s", file_string);
      
      c = $fgetc(fd);
      
      while (c != 'h1ff) begin
	 mem[i] = c;
	 $display("Got char [%0d] 0x%0h", i++, c);
	 c = $fgetc(fd);
      end
      
      mem[i++] = c;
      
      // Free/cons mem starts after expression bootstrap.
      free_pos = i;
      //mem_pos = i;
      
      DumpFile = fd;
   end   
endfunction // DumpFile

// InitTop - Creates everything needed at the top level. (Environments, constants, etc.)
function void InitTop;
   begin
      automatic sym_t symbolValue;
      
      // Create nil, t, and root environment.
      nil = Object("nil", Type_NIL);
      all_symbols = cons(nil, nil);
      root_env = cons(cons(nil, nil), nil);

      scratch = "t";
      s_t = MakeSymbol();
      
      // Probably won't work. Might need to write strings into scratch
      //scratch = "s_quote";
      //s_quote = MakeSymbol();
      scratch = "s_setq";
      s_setq = MakeSymbol();
      scratch = "";
      
      free_pos = 14;
      mem_pos = 14;
   
      //t = intern(Symbol("T"));
      
      // Need to move mem_pos & free_pos or something, here
      
   end
endfunction // InitTop

/* Interpreter start */
module interpreter();

   initial begin
      // Read file
      file_t file;
      status_t ret = status_ok;

      free_pos = 0;
      mem_pos = 0;

      InitMem();

      InitTop();
      
      
      file = DumpFile("/home/hrr4/Projects/lambda-lambda/exp.lisp");
      
      // Init mem (for GC)


      // Initialize top environment


      // null env.



      // Setup constants

      // Setup Primitives


      while (ret == status_ok) begin
	 // REPL here
	 ret = Print(Eval(root_env, Read(root_env)));
      end	 
   end
endmodule
