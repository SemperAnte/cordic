clc; clear; close all;

CORDIC_N    = 13; % number of iterations for CORDIC algorithm
OUT_WDT     = 19; % width of output sin/cos, sfi(OUT_WDT, OUT_WDT-2), <= FRQ_ACC_WDT 

% calc
x = -1 : 1e-2 : 1;
y = -1 : 1e-2 : 1;

x = repmat( x', 1, length( y ) )';
x = x(:)';
y = repmat( y, 1, length( x ) / length( y ) );

x = sfi( x, OUT_WDT, OUT_WDT - 1 );
y = sfi( y, OUT_WDT, OUT_WDT - 1 );

tic;
[ mag_fast, ph_fast ] = cordic_magph_fast( x, y, CORDIC_N );
toc;
%%
tic;
[ mag_mat, ph_mat ] = cordic_magph( x, y, CORDIC_N );
toc;
all(mag_mat == mag_fast)
all(ph_mat  == ph_fast)