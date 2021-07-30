//--------------------------------------------------------------------------------
// Project:       dsplib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    11.05.2016 - created
//    27.07.2021 - minor refactoring
//--------------------------------------------------------------------------------
// testbench for cordicCosSin
//--------------------------------------------------------------------------------
`timescale 1 ns / 100 ps

module tb_cordicCosSin();

    localparam int T = 10;    
    // parameters from generated file
    `include "parms.vh"     

    logic                            clk;
    logic                            reset;
    logic                            st;
    logic        [PHI_WIDTH - 1 : 0] phi;
    logic                            rdy;
    logic signed [PHI_WIDTH - 1 : 0] cos;
    logic signed [PHI_WIDTH - 1 : 0] sin;
   
    cordicCosSin
      #( .CORDIC_TYPE(CORDIC_TYPE),
         .N          (N          ),      
         .PHI_WIDTH    (PHI_WIDTH    ))
    uut
       (.clk  (clk  ),
        .reset(reset),
        .st   (st   ),
        .phi  (phi  ),
        .rdy  (rdy  ),
        .cos  (cos  ),
        .sin  (sin  ));
         
    always
    begin
        clk = 1'b1;
        #(T/2);
        clk = 1'b0;
        #(T/2);
    end
   
    initial
    begin
        reset = 1'b1;
        #(10*T + T/2);
        reset = 1'b0;
    end
   
    initial
    begin
        static int phiFile = $fopen("phi.txt", "r");      
        static int cosFile = $fopen("cos.txt", "w");
        static int sinFile = $fopen("sin.txt", "w");
        static int flagFile;
      
        if (phiFile == 0) begin
            $display("Cant open file phi.txt.");
            $stop;
        end
      
        st  = 1'b0;
        phi = '0;
      
        if (CORDIC_TYPE == "SERIAL") begin
            wait (rdy);
            @(negedge clk);
            while (!$feof(phiFile)) begin         
                st = 1'b1;
                // read phi from file
                $fscanf(phiFile, "%d\n", phi);
                #(T);
                st = 1'b0;
                wait (rdy);
                @(negedge clk);
                // write cos and sin to file
                $fwrite(cosFile, "%d\n", cos);
                $fwrite(sinFile, "%d\n", sin);
            end     
            phi = '0;             
            #(10 * T);    

        end else if (CORDIC_TYPE == "PARALLEL") begin
            @(negedge reset);
            #(10 * T);
            while (!$feof(phiFile)) begin
                @ (negedge clk);
                st = 1'b1;
                // read phi from file
                $fscanf(phiFile, "%d\n", phi);
                if (rdy) begin
                    // write cos and sin to file
                    $fwrite(cosFile, "%d\n", cos);
                    $fwrite(sinFile, "%d\n", sin);
                end
            end
            
            while (rdy) begin
                @ (negedge clk);
                st = 1'b0;
                phi = '0;
                // write cos and sin to file
                if (rdy) begin
                    $fwrite(cosFile, "%d\n", cos);
                    $fwrite(sinFile, "%d\n", sin);            
                end
            end
            # (10 * T);
        end else begin
            $display("Not correct parameter CORDIC_TYPE.");
        end
         
        $fclose(phiFile);
        $fclose(cosFile);
        $fclose(sinFile);
      
        // flag for automatic testbench
        flagFile = $fopen("flag.txt", "w");
        $fclose(flagFile);
        $stop;
    end
   
endmodule