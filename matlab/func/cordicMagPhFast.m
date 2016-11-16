function [ magCrd, phCrd ] = cordicMagPhFast( xCrd, yCrd, N )
% function [ magCrd, phCrd ] = cordicMagPhFast( xCrd, yCrd, N )
%
% calculate magnitude and phase by CORDIC algorithm
% accelerated version with casting fi to int64 and using parfor
% todo : add choices 'noph' 'noscl' 'nophnoscl', write c++ 
%
% xCrd, yCrd  - x, y coordinates, signed fi, must be same width
% N           - number of iterations

assert( xCrd.WordLength == yCrd.WordLength, 'X and Y coordinates must be same width' );
XY_WDT = xCrd.WordLength;

xCrd = int64( storedInteger( xCrd ) );
yCrd = int64( storedInteger( yCrd ) );
% check sign of x, algorithm requires x >= 0
qrt = ( xCrd < 0 ); % 2, 3 quarter
xCrd = abs( xCrd );

% lut table for arctangent
atanlut = int64( zeros( 1, N ) );
for i = 1 : N
   atanlut( i ) = atand( 2 ^ ( -( i - 1 ) ) ) / 90 * 2 ^ 62; 
   atanlut( i ) = bitshift( atanlut( i ), -( 62 - XY_WDT + 1 ) );   
end;
% coefficient of deformation value
coefd = 1;
for i = 0 : N - 1
    coefd = coefd / sqrt( 1 + 2^( -2 * i ) );
end;
coefd = int64( coefd * 2 ^ 62 );
coefd = bitshift( coefd, -( 62 - XY_WDT + 1 ) );

% debug info
if ( false )
    for i = 1 : length( atanlut )
        fprintf( 'N%i : atan = %i\n', i, atanlut( i ) );
    end
    fprintf( 'coefd = %i\n', coefd );
end

L = length( xCrd );
magCrd = int64( zeros( 1, L ) );
phCrd  = int64( zeros( 1, L ) );
scl = true( 1, L ); % index that need scaling on coefd
% CORDIC algorithm
parfor i = 1 : L
    x = xCrd( i );
    y = yCrd( i );
    z = int64( 0 );    
    % if y = 0, algorithm doesnt need
    if ( y == 0 )
        magCrd( i ) = x;
        phCrd( i )  = 0;
        scl( i )    = false; % dont need scaling
    else % CORDIC
        for j = 0 : N - 1
            xsh = bitshift( x, -j );
            ysh = bitshift( y, -j );
            % check sign
            if ( y < 0 ) 
                x = x - ysh;
                y = y + xsh;
                z = z - atanlut( j + 1 );
            else
                x = x + ysh;
                y = y - xsh;
                z = z + atanlut( j + 1 );
            end;
        end;
        magCrd( i ) = x;
        phCrd( i )  = z;      
    end;
end;

% chek sign of magnitude
magCrd( magCrd < 0 ) = 0;
% cast int64 to fi
magCrd = ufi( double( magCrd ) / 2 ^ ( XY_WDT - 1 ), XY_WDT + 1, XY_WDT - 1 );
coefd = ufi( double( coefd ) / 2 ^ ( XY_WDT - 1 ), XY_WDT - 1, XY_WDT - 1 );
F = fimath( 'ProductMode', 'SpecifyPrecision',...
            'ProductWordLength', XY_WDT + 1, ...
            'ProductFractionLength', XY_WDT - 1, ...
            'RoundingMethod', 'Floor');
magCrd( scl ) = mpy( F, magCrd( scl ), coefd );
magCrd = ufi( magCrd, XY_WDT, XY_WDT - 1 );
     
% saturate phase [ -pi/2 pi/2 ]
phCrd( phCrd >  2 ^ ( XY_WDT - 1 ) ) =  2 ^ ( XY_WDT - 1 );
phCrd( phCrd < -2 ^ ( XY_WDT - 1 ) ) = -2 ^ ( XY_WDT - 1 );  
% calc phase depending on quarter
ind = qrt & ( phCrd >= 0 );
phCrd( ind ) = 2 ^ XY_WDT - phCrd( ind );   % pi - z  
ind = qrt & phCrd < 0;
phCrd( ind ) = - 2 ^ XY_WDT - phCrd( ind ); % -pi - z
phCrd = sfi( double( phCrd ) / 2 ^ ( XY_WDT - 1 ), XY_WDT + 2, XY_WDT - 1 );
