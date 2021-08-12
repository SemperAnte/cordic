// short atan LUT
typedef logic [PKG_WIDTH - 3 : 0] atanType [N];
localparam atanType atanLUTshort = atanInit();
function atanType atanInit();
    for (int i = 0; i < N; i ++)
        atanInit[i] = atanLUTlong[i][61 -: PKG_WIDTH - 2];
endfunction

// single coefd
localparam int COEFD_LUT_LONG_SIZE = $size(coefdLUTlong, 1);
localparam logic [PKG_WIDTH - 3 : 0] coefd =
    (N - 1 > COEFD_LUT_LONG_SIZE - 1) ? coefdLUTlong[COEFD_LUT_LONG_SIZE - 1][61 -: PKG_WIDTH - 2]:
                                        coefdLUTlong[N - 1][61 -: PKG_WIDTH - 2];

//`define INFO_MODE // display LUT tables
`ifdef INFO_MODE
    initial begin
        for (int i = 0; i < N; i ++)
            $display("N%0d : atan = %d (%b)", i, atanLUTshort[i], atanLUTshort[i]);
        $display("coefd = %d (%b)", coefd, coefd);
    end
`endif

// signal saturate function   
// if (x >= 0100) x = 0100, if (x < 1100) x = 1100
function logic [PKG_WIDTH - 1 : 0] signalSaturate(input logic [PKG_WIDTH - 1 : 0] x);
    if (x[PKG_WIDTH - 1 : PKG_WIDTH - 2] == 2'b01) begin
        signalSaturate = {2'b01, {(PKG_WIDTH - 2){1'b0}}};
    end else if (x[PKG_WIDTH - 1 : PKG_WIDTH - 2] == 2'b10) begin
        signalSaturate = {2'b11, {(PKG_WIDTH - 2){1'b0}}};
    end else begin
        signalSaturate = x;
    end
endfunction