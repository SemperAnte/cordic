% CORDIC magnitude/phase algorithm
clc; clear; close all;
addpath( 'func' );

fpathSim = '..\sim\';
fpathModelsim  = 'D:\CADS\Modelsim10_1c\win32\modelsim.exe';

CORDIC_TYPE = 0;  % for testbench - '0' for "SERIAL", '1' for "PARALLEL"
CORDIC_N    = 13; % number of iterations for CORDIC algorithm
XY_WDT      = 18; % width of x/y inputs

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
% plot compare
if ( false )
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
if ( false )
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

%% create data for testbench
% file with parms
fileID = fopen( [ fpathSim 'parms.vh' ], 'wt' );
fprintf( fileID, '// Automatically generated with Matlab, dont edit\n' );
if ( ~CORDIC_TYPE )
    fprintf( fileID, 'localparam string CORDIC_TYPE = "SERIAL";\n' );
else
    fprintf( fileID, 'localparam string CORDIC_TYPE = "PARALLEL";\n' );
end
fprintf( fileID, 'localparam int N      = %i,\n', CORDIC_N );
fprintf( fileID, '               XY_WDT = %i;\n', XY_WDT );
fclose( fileID );
% files with x/y
txtFileWrite( [ fpathSim 'xin.txt' ], x, 'DEC' );
txtFileWrite( [ fpathSim 'yin.txt' ], y, 'DEC' );
%% autorun Modelsim
if ( exist( [ fpathSim 'flag.txt' ], 'file' ) )
     delete( [ fpathSim 'flag.txt' ] );
end;
status = system( [ fpathModelsim ' -do ' fpathSim 'autoMagPh.do' ] );
pause on;
while ( ~exist( [ fpathSim 'flag.txt' ], 'file' ) ) % wait for flag file
    pause( 1 );
end;

%% read data from testbench
NT = numerictype( magCrd );
magHdl = txtFileRead( [ fpathSim 'mag.txt' ], NT, 'DEC' );
NT = numerictype( phCrd );
phHdl  = txtFileRead( [ fpathSim 'ph.txt' ], NT, 'DEC'  );

if ( length( magCrd ) == length( magHdl ) )
    fprintf( 'length is equal = %i\n', length( magCrd ) );
    x = 1 : length( magCrd );    
elseif ( length( magCrd ) > length( magHdl ) )
    fprintf( 'length isnt equal, matlab = %i, hdl = %i\n', ...
        length( magCrd ), length( magHdl ) );
    x = 1 : length( magHdl );
else
    fprintf( 'length isnt equal, matlab = %i, hdl = %i\n', ...
    length( magCrd ), length( magHdl ) );
    x = 1 : length( magCrd );
end;

fprintf( 'num of errors for mag : %i\n', sum( magCrd( x ) ~= magHdl( x ) ) );
fprintf( 'num of errors for ph  : %i\n', sum( phCrd( x )  ~= phHdl( x ) ) );
if ( true )
    figure;
    subplot( 2, 1, 1 );
    plot( x, magCrd( x ), x, magHdl( x ) );
    title( 'mag' );
    legend( 'matlab', 'hdl' );
    grid on;    
    subplot( 2, 1, 2 );
    plot( x, phCrd( x ), x, phHdl( x ) );
    title( 'ph' );
    legend( 'matlab', 'hdl' );
    grid on; 
end