% CORDIC cosine/sine algorithm
clc; clear; close all;
addpath( 'func' );

fpathSim = '..\sim\';
fpathModelsim  = 'D:\CADS\Modelsim10_1c\win32\modelsim.exe';

CORDIC_TYPE = 1;  % for testbench - '0' for "SERIAL", '1' for "PARALLEL"
CORDIC_N    = 13; % number of iterations for CORDIC algorithm
PHI_WDT     = 18; % width of input angle phi (outputs is same width)  

% input angle phi
Npoints = 1.0e3;  % number of points
phiSign = 0;      % - '0' for unsigned, '1' for signed
phi = linspace( 0, 1, Npoints );
phi = phi - phiSign * 0.5;
phi = fi( phi, phiSign, PHI_WDT, PHI_WDT );

if ( ~CORDIC_TYPE )
    fprintf( 'CORDIC_TYPE = "SERIAL"\n' );
else
    fprintf( 'CORDIC_TYPE = "PARALLEL"\n' );
end
fprintf( 'CORDIC_N = %i\n', CORDIC_N );
fprintf( 'PHI_WDT  = %i\n', PHI_WDT );

% double
tic;
cosMat = cos( double( phi ) * 2 * pi );
sinMat = sin( double( phi ) * 2 * pi );
timeMat = toc;
% cordic fast
tic;
[ cosCrd, sinCrd ] = cordicCosSinFast( phi, CORDIC_N );
timeCrd = toc;
fprintf( 'time for matlab algorithm ( double    ) = %f s\n', timeMat );
fprintf( 'time for cordic algorithm ( integer   ) = %f s\n', timeCrd );

% plot compare
if ( true )
    figure;
    subplot( 2, 1, 1 );
    plot( phi, cosMat, phi, cosCrd );
    title( 'cos' );
    legend( 'double', 'cordic' );
    grid on;
    subplot( 2, 1, 2 );
    plot( phi, abs( cosMat - double( cosCrd ) ) );
    title( 'abs error' );
    line( [ phi( 1 ) phi( end ) ], [ eps( cosCrd ) eps( cosCrd ) ], ...
          'LineWidth', 2, 'Color', 'red' );
    grid on;    

    figure;
    subplot( 2, 1, 1 );
    plot( phi, sinMat, phi, sinCrd );
    title( 'sin' );
    legend( 'double', 'cordic' );
    grid on;
    subplot( 2, 1, 2 );
    plot( phi, abs( sinMat - double( sinCrd ) ) );
    title( 'abs error' );
    line( [ phi( 1 ) phi( end ) ], [ eps( sinCrd ) eps( sinCrd ) ], ...
          'LineWidth', 2, 'Color', 'red' );
    grid on;   
end

% check cordic slow version ( with fi objects ) if needed
if ( true )
    tic;
    [ cosSlow, sinSlow ] = cordicCosSinSlow( phi, CORDIC_N );
    timeSlow = toc;
    fprintf( 'time for cordic algorithm ( fi object ) = %f s\n', timeSlow );
    if ( any( cosSlow ~= cosCrd ) )
        warning( 'Outputs of fast and slow cosine cordic algorithms arent equal' );
    end
    if ( any( sinSlow ~= sinCrd ) )
        warning( 'Outputs of fast and slow sine cordic algorithms arent equal' );
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
fprintf( fileID, 'localparam int N       = %i,\n', CORDIC_N );
fprintf( fileID, '               PHI_WDT = %i;\n', PHI_WDT );
fclose( fileID );
% file with phi
txtFileWrite( [ fpathSim 'phi.txt' ], phi, 'DEC' );

%% autorun Modelsim
if ( exist( [ fpathSim 'flag.txt' ], 'file' ) )
     delete( [ fpathSim 'flag.txt' ] );
end;
status = system( [ fpathModelsim ' -do ' fpathSim 'autoCosSin.do' ] );
pause on;
while ( ~exist( [ fpathSim 'flag.txt' ], 'file' ) ) % wait for flag file
    pause( 1 );
end;

%% read data from testbench
NT = numerictype( cosCrd );
cosHdl = txtFileRead( [ fpathSim 'cos.txt' ], NT, 'DEC' );
sinHdl = txtFileRead( [ fpathSim 'sin.txt' ], NT, 'DEC' );

if ( length( cosCrd ) == length( cosHdl ) )
    fprintf( 'length is equal = %i\n', length( cosCrd ) );
    x = 1 : length( cosCrd );    
elseif ( length( cosCrd ) > length( cosHdl ) )
    fprintf( 'length isnt equal, matlab = %i, hdl = %i\n', ...
        length( cosCrd ), length( cosHdl ) );
    x = 1 : length( cosHdl );
else
    fprintf( 'length isnt equal, matlab = %i, hdl = %i\n', ...
    length( cosCrd ), length( cosHdl ) );
    x = 1 : length( cosCrd );
end;

fprintf( 'num of errors for cos: %i\n', sum( cosCrd( x ) ~= cosHdl( x ) ) );
fprintf( 'num of errors for sin: %i\n', sum( sinCrd( x ) ~= sinHdl( x ) ) );
if ( true )
    figure;
    subplot( 2, 1, 1 );
    plot( phi( x ), cosCrd( x ), phi( x ), cosHdl( x ) );
    title( 'cos' );
    legend( 'matlab', 'hdl' );
    grid on;    
    subplot( 2, 1, 2 );
    plot( phi( x ), sinCrd( x ), phi( x ), sinHdl( x ) );
    title( 'sin' );
    legend( 'matlab', 'hdl' );
    grid on; 
end