function [ mag_crd, ph_crd ] = cordic_magph_fast( x_crd, y_crd, N )
% function [ mag_crd, ph_crd ] = cordic_magph_fast( x_crd, y_crd, N )
%
% calculate magnitude and phase by CORDIC algorithm
% accelerated version with casting fi to int32 and using parfor
% todo : add choices 'noph' 'noscl' 'nophnoscl', write c++ 
%
% x_crd, y_crd  - x, y coordinate, signed fi, must be same width
% N             - number of iterations

XY_WDT = x_crd.WordLength;
x_crd = int32( storedInteger( x_crd ) );
y_crd = int32( storedInteger( y_crd ) );
% check sign of x, algorithm is required x >= 0
qrt = ( x_crd < 0 ); % 2, 3 quarter
x_crd = abs( x_crd );

% lut table for arctangent
atanlut = int32( zeros( 1, N ) );
for i = 1 : N
    if ( i <= ceil( N / 2 ) )
        atanlut( i ) = atand( 2 ^ ( -( i - 1 ) ) ) / 90 * 2 ^ ( XY_WDT - 1 ); 
    else
        atanlut( i ) = bitshift( atanlut( i - 1 ), -1 );
    end;
end;
% coefficient of deformation value
coefd = 1;
for i = 0 : N - 1
    coefd = coefd / sqrt( 1 + 2^( -2 * i ) );
end;
coefd = ufi( coefd, XY_WDT - 1, XY_WDT - 1 );

L = length( x_crd );
mag_crd = int32( zeros( 1, L ) );
ph_crd  = int32( zeros( 1, L ) );
scl = true( 1, L ); % index that need scaling on coefd
% CORDIC algorithm
parfor i = 1 : L
    x = x_crd( i );
    y = y_crd( i );
    z = int32( 0 );    
    % if y = 0, algorithm doesnt need
    if ( y == 0 )
        mag_crd( i ) = x; %!
        ph_crd( i )  = 0;
        scl( i ) = false; % dont need scaling
    else % CORDIC
        for j = 0 : N-1
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
        mag_crd( i ) = x;
        ph_crd( i ) = z;      
    end;
end;

% chek sign of magnitude
mag_crd( mag_crd < 0 ) = 0;
% cast int32 to fi
mag_crd = ufi( double( mag_crd ) / 2 ^ ( XY_WDT - 1 ), XY_WDT + 1, XY_WDT - 1 );
F = fimath( 'ProductMode', 'SpecifyPrecision',...
            'ProductWordLength', XY_WDT, ...
            'ProductFractionLength', XY_WDT - 1, ...
            'RoundingMethod', 'Floor');
mag_crd( scl ) = mpy( F, mag_crd( scl ), coefd );
        
% saturate phase [-pi/2 pi/2]
ph_crd( ph_crd >  2 ^ ( XY_WDT - 1 ) ) =  2 ^ ( XY_WDT - 1 );
ph_crd( ph_crd < -2 ^ ( XY_WDT - 1 ) ) = -2 ^ ( XY_WDT - 1 );
% calc phase depending on quarter
ind = qrt & ph_crd >= 0;
ph_crd( ind ) = 2 ^ XY_WDT - ph_crd( ind );   % pi - z  
ind = qrt & ph_crd < 0;
ph_crd( ind ) = - 2 ^ XY_WDT - ph_crd( ind ); % -pi - z
ph_crd = sfi( double( ph_crd ) / 2 ^ ( XY_WDT - 1 ), XY_WDT + 2, XY_WDT - 1 );
