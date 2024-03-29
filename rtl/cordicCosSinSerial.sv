//--------------------------------------------------------------------------------
// Project:       dsplib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    03.06.2016 - release
//    30.07.2021 - minor refactoring 
//--------------------------------------------------------------------------------
// serial architecture of CORDIC algorithm
// requires N + 2 clocks
//--------------------------------------------------------------------------------
module cordicCosSinSerial
   #(parameter int N,         // number of iterations for CORDIC algorithm
                   PHI_WIDTH) // width of input angle phi (outputs is same width)                
    (input  logic                            clk,
     input  logic                            reset,   // async reset
      
     input  logic                            st,      // force start calc
     input  logic        [PHI_WIDTH - 1 : 0] phi,     // input angle
            
     output logic                            rdy,     // result is ready, wait for st
     output logic signed [PHI_WIDTH - 1 : 0] cos,
     output logic signed [PHI_WIDTH - 1 : 0] sin);
   
    localparam N_WIDTH = $clog2(N);   
    // regs   
    logic signed [PHI_WIDTH - 1 : 0] x, y, z;    
    logic        [N_WIDTH   - 1 : 0] ni;      // number of iteration
    logic                            qrt;     // '1' for 2 or 3 quarter      
    // comb part
    logic signed [PHI_WIDTH - 1 : 0] phiCnv;
    logic signed [PHI_WIDTH - 1 : 0] xShift, yShift;
    logic        [PHI_WIDTH - 3 : 0] atan;
    logic signed [PHI_WIDTH - 1 : 0] xCnv, yCnv;      
   
    // fsm
    enum int unsigned {ST0, ST1, ST2, ST3} state;
      
    // long LUT tables for atan/coefd generated with Matlab
    `include "cordicLUT.vh"
    localparam int PKG_WIDTH = PHI_WIDTH;
    `include "cordicPkg.vh" 
   
    always_ff @(posedge clk, posedge reset)      
    if (reset) begin
        rdy   <= 1'b0;    
        cos   <= '0;
        sin   <= '0;
        x     <= '0;
        y     <= '0;
        z     <= '0;
        ni    <= '0;
        qrt   <= 1'b0;
        state <= ST0;
    end else begin
        if (st) begin // force start
            rdy   <= 1'b0;
            if (phi[PHI_WIDTH - 1] == phi[PHI_WIDTH - 2]) begin // 1, 4 quarter (00 or 11)
                qrt <= 1'b0;                             
            end else begin // 2, 3 quarter (01 or 10)  
                qrt <= 1'b1;            
            end
            ni    <= '0;
            z     <= phiCnv;
            state <= ST1;
        end else begin
            case (state)
                ST0: begin
                    rdy <= 1'b1;
                end
                ST1: begin // first CORDIC iteration
                    if (z >= 0) begin
                        x <= coefd;
                        y <= coefd;
                        z <= z - atan;
                    end else begin
                        x <= coefd;
                        y <= -coefd;
                        z <= z + atan;
                    end
                    ni    <= ni + 1'd1;
                    state <= ST2;
                end
                ST2: begin
                    // next CORDIC iteration
                    if (z >= 0) begin
                        x <= x - yShift;
                        y <= y + xShift;
                        z <= z - atan;                        
                    end else begin
                        x <= x + yShift;
                        y <= y - xShift;
                        z <= z + atan;
                    end                       
                    if (ni < N - 1) begin
                        ni    <= ni + 1'd1;
                        state <= ST2;
                    end else begin // ni = N-1, last iteration
                        state <= ST3;
                    end
                end
                ST3: begin
                    rdy   <= 1'b1;
                    cos   <= xCnv;
                    sin   <= yCnv;
                    state <= ST0;
                end
            endcase
        end
    end
   
    // comb part
    // transform phi angle from 0...2*pi to -pi/2...pi/2
    always_comb begin
        if (phi[PHI_WIDTH - 1] == phi[PHI_WIDTH - 2]) begin // 1, 4 quarter (00 or 11)
            phiCnv = phi; 
        end else begin 
            phiCnv = phi - 1'd1;
            phiCnv = {phiCnv[PHI_WIDTH - 1], ~phiCnv[PHI_WIDTH - 2 : 0]};  
        end
    end
    // shift
    assign xShift = x >>> ni;
    assign yShift = y >>> ni;
    assign atan = atanLUTshort[ni];
    // change sign for 2 or 3 quarter
    assign xCnv = (qrt) ? - signalSaturate(x) : signalSaturate(x);
    assign yCnv = signalSaturate(y);
   
endmodule