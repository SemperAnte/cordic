//--------------------------------------------------------------------------------
// File Name:     cordicMagPhSerial.sv
// Project:       cordic
// Author:        Shustov Aleksey ( SemperAnte ), semte@semte.ru
// History:
//    14.11.2016 - created
//--------------------------------------------------------------------------------
// calc magnitude and phase of inputs x, y by CORDIC algorithm
// architecture: serial   - requires N + 3 clocks
//               parallel - pipelined for N + 3 clocks
// see Matlab bit accurate model
//--------------------------------------------------------------------------------
module cordicMagPhSerial
   #( parameter int    N,       // number of iterations for CORDIC algorithm
                int    XY_WDT ) // width of input angle phi (outputs is same width)                
    ( input  logic                            clk,
      input  logic                            reset,   // async reset
      input  logic                            sclr,    // sync clear
      input  logic                            en,      // clock enable
      
      input  logic                            st,      // start calc
      input  logic signed [ XY_WDT - 1 : 0 ] xin,      // full range [ -1 1 )
      input  logic signed [ XY_WDT - 1 : 0 ] yin,      // full range [ -1 1 )
            
      output logic                           rdy,      // result is ready
      output logic        [ XY_WDT - 1 : 0 ] mag,      // range [ 0 ~1.41 ], unsigned
      output logic signed [ XY_WDT + 1 : 0 ] ph );     // range ( -pi( 1100.. ) ... pi( 0100.. ) ], signed
 
   localparam N_WDT = $clog2( N );
   // regs
   logic signed [ XY_WDT + 1 : 0 ] x, y, z;
   logic        [ N_WDT  - 1 : 0 ] ni;      // number of iteration
   logic                           qrt;     // '1' for 2 or 3 quarter
   // comb part
   logic signed [ XY_WDT + 1 : 0 ] xShift, yShift;
   
   // fsm
   enum int unsigned { ST0, ST1, ST2, ST3 } state;
   
   `define INFO_MODE    // display LUT values
   // full LUT tables for atan, coefd generated with Matlab
   `include "cordicLUT.vh"
   `include "cordicPkg.vh"
   
   always_ff @( posedge clk, posedge reset )
   if ( reset ) begin
      rdy   <= 1'b0;
      x     <= '0;
      y     <= '0;
      z     <= '0;
      ni    <= '0;
      qrt   <= 1'b0;
      state <= ST0;
   end else if ( en ) begin
      if ( sclr ) begin        // sync clear
         rdy   <= 1'b0;
         x     <= '0;
         z     <= '0;
         state <= ST0;
      end else if ( st ) begin // force start
         rdy <= 1'b0;         
         // check sign of input xin ( CORDIC algorithm works only for x >= 0)
         if ( xin < 0 ) begin
            x   <= -x;
            qrt <= 1'b1;
         end else begin // x >= 0
            x   <= x;
            qrt <= 1'b0;
         end
         y <= yin;
         
         state <= ST1;
      end else begin
         case ( state )
            ST0 : begin
               rdy <= 1'b1;
            end
            ST1 : begin
               // if y = 0 CORDIC algorithm doesn't required
               if ( ~|y ) begin // y == 0
                  rdy <= 1'b1;
                  
                  if ( ~qrt ) 
                     z <= '0;
                  else
                     z <= // 0100
                  state <= ST0; // finish algorithm
               end else begin // y != 0
                  if ( y < 0 ) begin
                     x <= x - y;
                     y <= y + x;
                     z <= -atan;
                  end else begin
                     x <= x + y;
                     y <= y - x;
                     z <= atan;
                  end                  
                  ni    <= ni + 1'd1;                  
                  state <= ST2;
               end
            end
            ST2 : begin
               if ( y < 0 ) begin
                  x <= x - yShift;
                  y <= y + xShift;
                  z <= z - atan;
               end else begin
                  x <= x + yShift;
                  y <= y - xShift;
                  z <= z + atan;
               end
               if ( ni < N - 1 ) begin // next iteration
                  ni    <= ni + 1;
                  state <= ST2;
               end else begin
                  ni    <= '0;
                  state <= ST3;
               end                  
            end
            ST3 : begin
               
               // convert output phi
               if ( ~qrt ) begin // 1 or 4 quarter
                  z <= z;
               end else begin    // 2 or 3 quarter
                  if ( z >= 0 )
                     z <= { 2'b01, { XY_WDT - 1 { 1'b0 } } } - z; //  pi - z
                  else // z < 0
                     z <= { 2'b11, { XY_WDT - 1 { 1'b0 } } } - z; // -pi - z
               end
               state <= ST0;
            end
         endcase
      end
   end
   
   // shift reg
   assign xShift = x >>> ni;
   assign yShift = y >>> ni;
   assign atan   = atanLUTshort[ ni ];
   
   // outputs
   assign mag = x[ XY_WDT - 1 : 0 ];
   assign ph  = z;
     
endmodule