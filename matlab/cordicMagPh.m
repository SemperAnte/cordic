% CORDIC magnitude/phase algorithm
clc; clear; close all;
addpath( 'func' );

fpathTestbench = '..\sim\';
fpathModelsim  = 'D:\CADS\Modelsim10_1c\win32\modelsim.exe';

CORDIC_TYPE = 0;  % for testbench - '0' for "SERIAL", '1' for "PARALLEL"
CORDIC_N = 13;    % number of iterations for CORDIC algorithm
XY_WDT   = 18;    % width of x/y inputs

% x/y inputs
x = -1 : 1e-2 : 1;
y = -1 : 1e-2 : 1;
x = repmat( x', 1, length( y ) )';
x = x( : )';
y = repmat( y, 1, length( x ) / length( y ) );
x = sfi( x, XY_WDT, XY_WDT - 1 );
y = sfi( y, XY_WDT, XY_WDT - 1 );

if ( ~CORDIC_TYPE )
    fprintf( 'CORDIC_TYPE = "SERIAL"\n' );
else
    fprintf( 'CORDIC_TYPE = "PARALLEL"\n' );
end
fprintf( 'CORDIC_N = %i\n', CORDIC_N );
fprintf( 'XY_WDT   = %i\n', XY_WDT );

% double
tic;
magMat = abs( double( x ) + 1j * double( y ) );
phMat  = angle( double( x ) + 1j * double( y ) ) / ( pi / 2 );
timeMat = toc;
% cordic fast
tic;
[ magCrd, phCrd ] = cordicMagPhFast( x, y, CORDIC_N );
timeCrd = toc;
fprintf( 'time for matlab algorithm ( double    ) = %f s\n', timeMat );
fprintf( 'time for cordic algorithm ( integer   ) = %f s\n', timeCrd );

if ( true )
    figure;
    subplot( 2, 1, 1 );
    plot( 1 : length( magMat ), magMat, 1 : length( magCrd ), magCrd );
    title( 'magnitude' );
    legend( 'double', 'cordic' );
    grid on;
    subplot( 2, 1, 2 );
    plot( abs( magMat - double( magCrd ) ) );
    title( 'abs error' );
    line( [ 1 length( magCrd ) ], [ eps( magCrd ) eps( magCrd ) ], ...
          'LineWidth', 2, 'Color', 'red' );
    grid on;    

    figure;
    subplot( 2, 1, 1 );
    plot( 1 : length( phMat ), phMat, 1 : length( phCrd ), phCrd );
    title( 'phase' );
    legend( 'double', 'cordic' );
    grid on;
    subplot( 2, 1, 2 );
    plot( abs( phMat - double( phCrd ) ) );
    title( 'abs error' );
    line( [ 1 length( phCrd ) ], [ eps( phCrd ) eps( phCrd ) ], ...
          'LineWidth', 2, 'Color', 'red' );
    grid on;   
end

% check cordic slow version ( with fi objects ) if needed
if ( true )
    tic;
    [ magSlow, phSlow ] = cordicMagPhSlow( x, y, CORDIC_N );
    timeSlow = toc;
    fprintf( 'time for cordic algorithm ( fi object ) = %f s\n', timeSlow );
    if ( any( magSlow ~= magCrd ) )
        warning( 'Outputs of fast and slow magnitude cordic algorithms arent equal' );
    end
    if ( any( phSlow ~= phCrd ) )
        warning( 'Outputs of fast and slow phase cordic algorithms arent equal' );
    end
end