`timescale 1 ns / 100 ps

module tb_cordicMagPh();

   localparam int    T = 10;    
   // parameters from generated file
   `include "parms.vh"     

   logic                            clk;
   logic                            reset;
   logic                            sclr;
   logic                            en;
   logic                            st;
   logic signed  [ XY_WDT - 1 : 0 ] xin;
   logic signed  [ XY_WDT - 1 : 0 ] yin;   
   logic                            rdy;
   logic         [ XY_WDT - 1 : 0 ] mag;
   logic signed  [ XY_WDT + 1 : 0 ] ph;
   
   cordicMagPh
      #( .CORDIC_TYPE ( CORDIC_TYPE ),
         .N           ( N           ),      
         .XY_WDT      ( XY_WDT      ) )
   uut
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
         
   always
   begin
      clk = 1'b1;
      #( T / 2 );
      clk = 1'b0;
      #( T / 2 );
   end
   
   initial
   begin
      reset = 1'b1;
      #( 10 * T + T / 2 );
      reset = 1'b0;
   end
   
   initial
   begin
      sclr = 1'b0;
      en   = 1'b1;
   end
   
   initial
   begin
      static int xinFile = $fopen( "xin.txt", "r" );      
      static int yinFile = $fopen( "yin.txt", "r" ); 
      static int magFile = $fopen( "mag.txt", "w" );
      static int phFile  = $fopen( "ph.txt",  "w" );
      static int flagFile;
      
      if ( !xinFile )
         $display( "Cant open file xin.txt" );
      if ( !yinFile )
         $display( "Cant open file yin.txt" );
      if ( !xinFile || !yinFile )
         $stop;
      
      st  = 1'b0;
      xin = '0;
      yin = '0;
      
      if ( CORDIC_TYPE == "SERIAL" ) begin
         wait ( rdy );
         @ ( negedge clk );
         while ( !$feof( xinFile ) || !$feof( yinFile ) ) begin         
            st = 1'b1;
            // read xin and yin from file
            $fscanf( xinFile, "%d\n", xin );
            $fscanf( yinFile, "%d\n", yin );            
            # ( T );
            st = 1'b0;
            wait ( rdy );
            @ ( negedge clk );
            // write mag and ph to file
            $fwrite( magFile, "%d\n", mag );
            $fwrite( phFile,  "%d\n", ph  );
         end     
         xin = '0;             
         yin = '0;             
         # ( 10 * T );    

/*       end 
      else if ( CORDIC_TYPE == "PARALLEL" ) begin
         bit eof = 1'b0;
         @ ( negedge reset );
         # ( 10 * T );
         while ( !$feof( phiFile ) ) begin
            @ ( negedge clk );
            st = 1'b1;
            // read phi from file
            $fscanf( phiFile, "%d\n", phi );
            if ( rdy ) begin
               // write cos and sin to file
               $fwrite( cosFile, "%d\n", cos );
               $fwrite( sinFile, "%d\n", sin );
            end
         end
         while ( rdy ) begin
            @ ( negedge clk );
            st  = 1'b0;
            phi = '0;
            // write cos and sin to file
            if ( rdy ) begin
               $fwrite( cosFile, "%d\n", cos );
               $fwrite( sinFile, "%d\n", sin );            
            end
         end
         # ( 10 * T ); */
      end else
         $display( "Not correct parameter CORDIC_TYPE" );
         
      $fclose( xinFile );
      $fclose( yinFile );      
      $fclose( magFile );
      $fclose( phFile  );
      
      // flag for automatic testbench
      flagFile = $fopen( "flag.txt", "w" );
      $fclose( flagFile );
      $stop;
   end
   
endmodule