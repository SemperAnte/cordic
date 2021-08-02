//--------------------------------------------------------------------------------
// Project:       dsplib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    14.11.2016 - created
//    16.11.2016 - done, verified with Matlab
//    02.08.2021 - minor refactoring
//--------------------------------------------------------------------------------
// serial architecture for CORDIC algorithm
// requires N + 2 clocks
//--------------------------------------------------------------------------------
module cordicMagPhSerial
   #(parameter int N,        // number of iterations for CORDIC algorithm
               int XY_WIDTH) // width of inputs x, y                
    (input  logic                           clk,
     input  logic                           reset,   // async reset
     
     input  logic                           st,      // start calc
     input  logic signed [XY_WIDTH - 1 : 0] xin,     // full range [-1 1)
     input  logic signed [XY_WIDTH - 1 : 0] yin,     // full range [-1 1)
           
     output logic                           rdy,     // result is ready
     output logic        [XY_WIDTH - 1 : 0] mag,     // range [0 ~1.41], unsigned
     output logic signed [XY_WIDTH + 1 : 0] ph);     // range (-pi(1100..) ... pi(0100..)], signed 2 bit wider than XY_WIDTH
 
    localparam N_WIDTH = $clog2(N);
    // regs
    logic signed [XY_WIDTH + 1 : 0] x, y, z;
    logic        [N_WIDTH  - 1 : 0] ni;      // number of iteration
    logic                           qrt;     // '1' for 2 or 3 quarter (i.e. xin < 0)
    // comb part
    logic signed [XY_WIDTH + 1 : 0] xShift, yShift;
    logic        [XY_WIDTH - 2 : 0] atan;
    logic signed [XY_WIDTH + 1 : 0] zCnv;
    // comb, multiplier r = a * coefd
    logic         [XY_WIDTH : 0] a;
    logic [2 * XY_WIDTH - 1 : 0] r;

    // fsm
    enum int unsigned {ST0, ST1, ST2, ST3} state;   

    `define INFO_MODE    // display LUT values
    // full LUT tables for atan, coefd generated with Matlab
    `include "cordicLUT.vh"
    localparam int PKG_WIDTH = XY_WIDTH + 1;
    `include "cordicPkg.vh"
   
    always_ff @(posedge clk, posedge reset)
    if (reset) begin
        rdy   <= 1'b0;
        x     <= '0;
        y     <= '0;
        z     <= '0;
        ni    <= '0;
        qrt   <= 1'b0;
        state <= ST0;
    end else begin
        if (st) begin // force start
            rdy <= 1'b0;         
            // check sign of input xin (CORDIC algorithm works only for x >= 0)
            if (xin < 0) begin
                x   <= -xin;
                qrt <= 1'b1;
            end else begin // xin >= 0
                x   <= xin;
                qrt <= 1'b0;
            end
            y <= yin;
         
            state <= ST1;
        end else begin
            case (state)
                ST0: begin
                    rdy <= 1'b1;
                end
                ST1: begin
                    // if y = 0 CORDIC algorithm doesn't required
                    if (y == 0) begin // y == 0
                        rdy <= 1'b1;
                      
                        if (~qrt) begin // xin was >= 0 
                            z <= '0;
                        end else begin
                            z <= {2'b01, {XY_WIDTH{1'b0}}}; // phi = pi, 0100 ...
                        end
                        state <= ST0; // finish algorithm
                    end else begin // y != 0, use CORDIC algorithm
                        if (y < 0) begin
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
                ST2: begin
                    if (y < 0) begin
                        x <= x - yShift;
                        y <= y + xShift;
                        z <= z - atan;
                    end else begin // y >= 0
                        x <= x + yShift;
                        y <= y - xShift;
                        z <= z + atan;
                    end
                    if (ni < N - 1) begin // next iteration
                        ni    <= ni + 1'd1;
                        state <= ST2;
                    end else begin
                        ni    <= '0;
                        state <= ST3;
                    end                  
                end
                ST3: begin    
                    rdy   <= 1'b1;
                    x     <= {1'b0, r[2 * XY_WIDTH - 1 : XY_WIDTH - 1]};
                    z     <= zCnv;
                    state <= ST0;
                end
            endcase
        end
   end
   
    // shift
    assign xShift = x >>> ni;
    assign yShift = y >>> ni;
    assign atan   = atanLUTshort[ni];   
    // multiplier r = a * coefd
    always_comb begin
        if (x >= 0) begin
            a = x[XY_WIDTH : 0];
        end else begin
            a = '0;
        end
        r = a * coefd;
    end   
    // z transform for last interation
    always_comb begin      
        // limit z [-pi/2 ... pi/2]
        zCnv = {z[XY_WIDTH + 1], signalSaturate(z[XY_WIDTH : 0])};     
      
        if (~qrt) begin // 1 or 4 quarter
            zCnv = zCnv;
        end else begin    // 2 or 3 quarter
            if (zCnv >= 0) begin
                zCnv = {2'b01, {XY_WIDTH{1'b0}}} - zCnv; //  pi - z
            end else begin
                zCnv = {2'b11, {XY_WIDTH{1'b0}}} - zCnv; // -pi - z
            end
        end      
    end
   
    // outputs
    assign mag = x[XY_WIDTH - 1 : 0];
    assign ph  = z;
   
endmodule