//--------------------------------------------------------------------------------
// Project:       dsplib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    14.11.2016 - created
//    16.11.2016 - serial architecture is completed
//    30.07.2021 - minor refactoring
//--------------------------------------------------------------------------------
// calculate magnitude/phase of inputs x, y with CORDIC algorithm
// architecture: serial   - requires N + 2 clocks
//               parallel - pipelined for N + 2 clocks (not ready yet)
// see Matlab bit accurate model
//--------------------------------------------------------------------------------
module cordicMagPh
   #(parameter string CORDIC_TYPE = "SERIAL",     // "PARALLEL" (not ready yet) or "SERIAL"
               int    N        = 13,              // number of iterations for CORDIC algorithm
               int    XY_WIDTH = 18)              // width of inputs x, y                 
    (input  logic                           clk,
     input  logic                           reset, // async reset
      
     input  logic                           st,    // start calc
     input  logic signed [XY_WIDTH - 1 : 0] xin,   // full range [-1 1)
     input  logic signed [XY_WIDTH - 1 : 0] yin,   // full range [-1 1)
            
     output logic                           rdy,   // result is ready
     output logic        [XY_WIDTH - 1 : 0] mag,   // range [0 ~1.41], unsigned
     output logic signed [XY_WIDTH + 1 : 0] ph);   // range (-pi(1100..) ... pi(0100..)], signed 2, bit wider XY_WIDTH
 
    generate
        if (CORDIC_TYPE == "SERIAL") begin // serial architecture
            cordicMagPhSerial
               #(.N       (N       ),
                 .XY_WIDTH(XY_WIDTH))
            cordicMagPhSerialInst
                (.clk  (clk  ),
                 .reset(reset),
                 .st   (st   ),
                 .xin  (xin  ),
                 .yin  (yin  ),
                 .rdy  (rdy  ),
                 .mag  (mag  ),
                 .ph   (ph   ));
        end else begin
            initial begin
                $error("Not correct parameter CORDIC_TYPE.");
            end
        end
    endgenerate
     
endmodule