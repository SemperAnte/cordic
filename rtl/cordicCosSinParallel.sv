//--------------------------------------------------------------------------------
// Project:       dsplib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    03.06.2016 - release
//    30.07.2021 - minor refactoring
//--------------------------------------------------------------------------------
// parallel architecture for CORDIC algorithm
// pipelined for N + 2 clocks
//--------------------------------------------------------------------------------
module cordicCosSinParallel
   #(parameter int N,         // number of iterations for CORDIC algorithm
                   PHI_WIDTH) // width of input angle phi (outputs is same width)                
    (input  logic                            clk,
     input  logic                            reset,   // async reset
      
     input  logic                            st,      // start calc
     input  logic        [PHI_WIDTH - 1 : 0] phi,     // input angle
            
     output logic                            rdy,     // result is ready
     output logic signed [PHI_WIDTH - 1 : 0] cos,
     output logic signed [PHI_WIDTH - 1 : 0] sin);   
 
    // regs   
    logic signed [PHI_WIDTH - 1 : 0] x [N + 1];
    logic signed [PHI_WIDTH - 1 : 0] y [N + 1];    
    logic signed [PHI_WIDTH - 1 : 0] z [N];
    logic        [N           : 0] qrt;     // '1' for 2 or 3 quarter 
    logic        [N + 1       : 0] rdyReg;
   
    // comb part
    logic signed [PHI_WIDTH - 1 : 0] phiCnv;
    logic signed [PHI_WIDTH - 1 : 0] xShift [N - 1];
    logic signed [PHI_WIDTH - 1 : 0] yShift [N - 1];
    logic signed [PHI_WIDTH - 1 : 0] xCnv, yCnv;      
   
    `define INFO_MODE    // display LUT values
    // full LUT tables for atan, coefd generated with Matlab
    `include "cordicLUT.vh"
    localparam int PKG_WIDTH = PHI_WIDTH;
    `include "cordicPkg.vh"
   
    always_ff @(posedge clk, posedge reset)
    if ( reset ) begin
        x <= '{default : '0};
        y <= '{default : '0};
        z <= '{default : '0};
        qrt    <= '0;
        rdyReg <= '0;
    end else begin
        // rdy
        rdyReg <= {st, rdyReg[N + 1 : 1]};
        // qrt
        if (phi[PHI_WIDTH - 1] == phi[PHI_WIDTH - 2]) begin // 1, 4 quarter (00 or 11)
            qrt[N] <= 1'b0;
        end else begin // 2, 3 quarter (01 or 10)
            qrt[N] <= 1'b1;
        end
        qrt[N - 1 : 0] <= qrt[N : 1];
        // z
        z[N - 1] <= phiCnv;
        for (int i = 0; i < N - 1; i++) begin
            if (z[N - 1 - i] >= 0) begin               
                z[N - 2 - i] <= z[N - 1 - i] - atanLUTshort[i];
            end else begin
                z[N - 2 - i] <= z[N - 1 - i] + atanLUTshort[i];    
            end
        end 
        // x, y   
        if (z[N - 1] >= 0) begin
            x[N] <= coefd;
            y[N] <= coefd;
        end else begin
            x[N] <= coefd;
            y[N] <= -coefd;
        end
        for (int i = 0; i < N - 1; i++) begin // N - 1 ... 1
            if (z[N - 2 - i] >= 0 ) begin
                x[N - 1 - i] <= x[N - i] - yShift[N - 2 - i];
                y[N - 1 - i] <= y[N - i] + xShift[N - 2 - i];
            end else begin
                x[N - 1 - i] <= x[N - i] + yShift[N - 2 - i];
                y[N - 1 - i] <= y[N - i] - xShift[N - 2 - i];
            end
            x[0] <= xCnv;
            y[0] <= yCnv;
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
    // shift reg
    always_comb begin
        for (int i = 0; i < N - 1; i++) begin
            xShift[N - 2 - i] = x[N - i] >>> (i + 1);
            yShift[N - 2 - i] = y[N - i] >>> (i + 1);
        end
    end
    // for 2 or 3 quarter change sign
    assign xCnv = (qrt[0]) ? - signalSaturate(x[1]) : signalSaturate(x[1]);
    assign yCnv = signalSaturate(y[1]);
   
    // outputs
    assign rdy = rdyReg[0];
    assign cos = x[0];
    assign sin = y[0];
     
endmodule