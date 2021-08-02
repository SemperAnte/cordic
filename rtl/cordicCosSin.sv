//--------------------------------------------------------------------------------
// Project:       dsplib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    11.05.2016 - verified with Modelsim and Matlab
//    13.05.2016 - add SV LUT tables for atan, coefd
//    03.06.2016 - release
//    30.07.2021 - minor refactoring
//--------------------------------------------------------------------------------
// calculate cosine/sine of input angle phi with CORDIC algorithm
// architecture: serial   - requires N + 2 clocks
//               parallel - pipelined for N + 2 clocks
// input angle: unsigned fi [  0(0000..) ... 2*pi(1111..)) or
//                signed fi [-pi(1000..) ...   pi(0111..))
// see Matlab bit-accurate model
//--------------------------------------------------------------------------------
module cordicCosSin
   #(parameter string CORDIC_TYPE = "SERIAL",  // "PARALLEL" or "SERIAL"
               int    N           = 13,        // number of iterations for CORDIC algorithm
               int    PHI_WIDTH   = 18)        // width of input angle phi (outputs is same width)                
    (input  logic                            clk,
     input  logic                            reset,   // async reset
      
     input  logic                            st,      // force start calc
     input  logic        [PHI_WIDTH - 1 : 0] phi,     // input angle
            
     output logic                            rdy,     // result is ready
     output logic signed [PHI_WIDTH - 1 : 0] cos,
     output logic signed [PHI_WIDTH - 1 : 0] sin);   
 
    generate
        if (CORDIC_TYPE == "PARALLEL") begin // parallel architecture
            cordicCosSinParallel
               #(.N        (N        ),
                 .PHI_WIDTH(PHI_WIDTH))
            cordicCosSinParallelInst
                (.clk  (clk  ),
                 .reset(reset),
                 .st   (st   ),
                 .phi  (phi  ),
                 .rdy  (rdy  ),
                 .cos  (cos  ),
                 .sin  (sin  ));
        end else if (CORDIC_TYPE == "SERIAL") begin // serial architecture
            cordicCosSinSerial
                #(.N        (N        ),
                  .PHI_WIDTH(PHI_WIDTH))
            cordicCosSinSerialInst
                (.clk  (clk  ),
                 .reset(reset),
                 .st   (st   ),
                 .phi  (phi  ),
                 .rdy  (rdy  ),
                 .cos  (cos  ),
                 .sin  (sin  ));
        end else begin
            initial begin
                $error("Not correct parameter CORDIC_TYPE.");
            end
        end
    endgenerate
     
endmodule