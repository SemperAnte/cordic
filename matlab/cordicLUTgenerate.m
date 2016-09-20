% create file with LUT tables for atan and coefd
% for including to cordic rtl project
clc; clear;

filePath = '..\rtl\cordicLUT.vh';

% LUT table for arctangent
maxSizeLUT = 64;
atanLUTfull = uint64( zeros( 1, maxSizeLUT ) );
for i = 1 : maxSizeLUT
   atanDbl = atand( 2 ^ ( -( i - 1 ) ) ) / 90;
   atanLUTfull( i ) = uint64( atanDbl * ( 2 ^ 62 ) );
end;

% LUT table for coefd
maxSizeLUT = 26; 
coefdDbl   = 1;
coefdLUTfull = uint64( zeros( 1, maxSizeLUT ) );
for i = 0 : maxSizeLUT - 1
    coefdDbl = coefdDbl / sqrt( 1 + 2^( -2 * i ) );
    coefdLUTfull( i + 1 ) = uint64( coefdDbl * ( 2 ^ 62 ) );
end;

% generate code file
fileID = fopen( filePath, 'wt' );
fprintf( fileID, '// full LUT tables for atan and coefd\n' );
fprintf( fileID, '// Automatically generated with Matlab, dont edit\n' );
fprintf( fileID, 'localparam logic [ 63 : 0 ] atanLUTfull [ %i ] = ''{\n', length( atanLUTfull ) );
for i = 1 : length( atanLUTfull )
    fprintf( fileID, '      64''d%i', atanLUTfull( i ) );
    if ( i == length( atanLUTfull ) )
        fprintf( fileID, ' };\n' );
    else
        fprintf( fileID, ',\n' );
    end
end
fprintf( fileID, '\n' );
fprintf( fileID, 'localparam logic [ 63 : 0 ] coefdLUTfull [ %i ] = ''{\n', length( coefdLUTfull ) );
for i = 1 : length( coefdLUTfull )
    fprintf( fileID, '      64''d%i', coefdLUTfull( i ) );
    if ( i == length( coefdLUTfull ) )
        fprintf( fileID, ' };' );
    else
        fprintf( fileID, ',\n' );
    end
end
fclose( fileID );