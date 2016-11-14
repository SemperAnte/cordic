//--------------------------------------------------------------------------------
// File Name:     cordicMagPh.sv
// Project:       cordic
// Author:        Shustov Aleksey ( SemperAnte ), semte@semte.ru
// History:
//    14.11.2016 - 0.1, created
//--------------------------------------------------------------------------------
// calc magnitude and phase of inputs x, y by CORDIC algorithm
// architecture: serial   - requires N + 3 clocks
//               parallel - pipelined for N + 3 clocks
// see Matlab bit accurate model
//--------------------------------------------------------------------------------
module cordicMagPh
   #( parameter string CORDIC_TYPE = "SERIAL",         // "PARALLEL" ( not ready yet ) or "SERIAL"
                int    N           = 13,               // number of iterations for CORDIC algorithm
                int    XY_WDT      = 18 )              // width of input angle phi (outputs is same width)                
    ( input  logic                            clk,
      input  logic                            reset,   // async reset
      input  logic                            sclr,    // sync clear
      input  logic                            en,      // clock enable
      
      input  logic                            st,      // start calc
      input  logic signed [ XY_WDT - 1 : 0 ] xin,      // full range [ -1 1 )
      input  logic signed [ XY_WDT - 1 : 0 ] yin,      // full range [ -1 1 )
            
      output logic                           rdy,      // result is ready
      output logic        [ XY_WDT - 1 : 0 ] mag,      // range [ 0 ~1.41 ], unsigned
      output logic        [ XY_WDT + 1 : 0 ] ph );     // range ( -pi( 1100.. ) ... pi( 0100.. ) ]
 
   generate
      if ( CORDIC_TYPE == "SERIAL" ) begin // serial architecture
         cordicMagPhSerial
            #( .N       ( N       ),
               .XY_WDT  ( XY_WDT  ) )
         cordicMagPhSerialInst
             ( .clk   ( clk   ),
               .reset ( reset ),
               .sclr  ( sclr  ),
               .en    ( en    ),
               .st    ( st    ),
               .xin   ( xin   ),
               .yin   ( yin   ),
               .rdy   ( rdy   ),
               .mag   ( mag   ),
               .ph    ( ph    ) );
      end else begin
         initial
            $error( "Not correct parameter, CORDIC_TYPE" );
      end
   endgenerate
     
endmodule