// short atan LUT
typedef logic [ PKG_WDT - 3 : 0 ] atanType [ N ];
localparam atanType atanLUTshort = atanInit();
function atanType atanInit();
   for ( int i = 0; i < N; i ++ )
      atanInit[ i ] = atanLUTfull[ i ][ 61 -: PKG_WDT - 2 ];
endfunction

// single coefd
localparam logic [ PKG_WDT - 3 : 0 ] coefd = ( N - 1 > 25 ) ? coefdLUTfull[ 25    ][ 61 -: PKG_WDT - 2 ]:
                                                              coefdLUTfull[ N - 1 ][ 61 -: PKG_WDT - 2 ];

`ifdef INFO_MODE
   initial begin
      for ( int i = 0; i < N; i ++ )
         $display( "N%0d : atan = %d ( %b )", i, atanLUTshort[ i ], atanLUTshort[ i ] );
      $display( "coefd = %d ( %b )", coefd, coefd );
   end
`endif

// signal saturate function   
// if (x >= 0100) x = 0100, if (x < 1100) x = 1100
function logic [ PKG_WDT - 1 : 0 ] signalSaturate( input logic [ PKG_WDT - 1 : 0] x );
   if ( x[ PKG_WDT - 1 : PKG_WDT - 2 ] == 2'b01 ) begin
      signalSaturate = { 2'b01, { PKG_WDT - 2 { 1'b0 } } };
   end else if ( x[ PKG_WDT - 1 : PKG_WDT - 2 ] == 2'b10 ) begin
      signalSaturate = { 2'b11, { PKG_WDT - 2 { 1'b0 } } };
   end else begin
      signalSaturate = x;
   end
endfunction