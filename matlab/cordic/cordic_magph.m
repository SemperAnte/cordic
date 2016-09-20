function [ mag_crd, ph_crd ] = cordic_magph( x_crd, y_crd, N )
% function [ mag_crd, ph_crd ] = cordic_magph( x_crd, y_crd, N, 'nophcoefd' )
%
% calculate magnitude and phase by CORDIC algorithm
% 
% x_crd, y_crd  - x, y coordinate, signed fi, must be same width
% N             - number of iterations

XY_WDT = x_crd.WordLength;

% lut table for arctangent
atanlut = ufi( zeros( 1, N ), XY_WDT - 1, XY_WDT - 1 );
for i = 1 : N
    if ( i <= ceil( N / 2 ) ) 
        atanlut( i ) = atand( 2 ^ ( -( i - 1 ) ) ) / 90; 
    else
        atanlut( i ) = bitsrl( atanlut( i - 1 ), 1 );
    end;
end;
% coefficient of deformation value
coefd = 1;
for i = 0 : N - 1
    coefd = coefd / sqrt( 1 + 2^( -2 * i ) );
end;
coefd = ufi( coefd, XY_WDT - 1, XY_WDT - 1 );

L = length( x_crd );
T = numerictype( 1, XY_WDT + 2, XY_WDT - 1 );
F = fimath( 'ProductMode', 'SpecifyPrecision',...
            'ProductWordLength', XY_WDT + 1, ...
            'ProductFractionLength', XY_WDT - 1, ...
            'RoundingMethod', 'Floor');
mag_crd = fi( zeros( 1, L ), 0, XY_WDT, XY_WDT - 1 );
ph_crd  = fi( ones( 1, L ), T );
% CORDIC algorithm
x   = fi( 0, T );
y   = fi( 0, T );
z   = fi( 0, T );
for i = 1 : L
    x( : ) = x_crd( i );
    y( : ) = y_crd( i );
    z( : ) = 0;
    % check sign of x, algorithm is required x >= 0
    if ( x < 0 )
        qrt = true;  % 2, 3 quarter
        x( : ) = abs( x );        
    else
        qrt = false; % 1, 4 quarter
    end;    
    % if y = 0, algorithm doesnt need
    if ( y == 0 )
        mag_crd( i ) = x;
        if ( qrt == 0 )
            ph_crd( i ) = 0;
        else % x < 0
            ph_crd( i ) = 2; % pi
        end;
    else % CORDIC
        for j = 0 : N-1
            xsh = bitsra( x, j );
            ysh = bitsra( y, j );
            % check sign
            if ( y < 0 ) 
                x = accumneg( x, ysh, 'Floor', 'Wrap' );
                y = accumpos( y, xsh, 'Floor', 'Wrap' );
                z = accumneg( z, atanlut( j + 1 ), 'Floor', 'Wrap' );
            else
                x = accumpos( x, ysh, 'Floor', 'Wrap' );
                y = accumneg( y, xsh, 'Floor', 'Wrap' );
                z = accumpos( z, atanlut( j + 1 ), 'Floor', 'Wrap' );
            end;
        end;
        % multiply magnitude on coefd
        if ( x >= 0)
            mag_crd( i ) = mpy( F, x, coefd );
        else % x < 0 - set magnitude = 0
            mag_crd( i ) = 0;
        end;
        % saturate phase [-pi/2 pi/2]
        if (z > 1)
            z( : ) = 1;
        elseif ( z < -1)
            z( : ) = -1;
        end;
        % calc phase depending on quarter
        if (qrt == false) % 1, 4 quarter    
            ph_crd( i ) = z;
        else              % 2, 3 quarter
            if ( z >= 0 )
                ph_crd( i ) = accumpos( -z,  2, 'Floor', 'Wrap' ); % pi - z           
            else % z < 0
                ph_crd( i ) = accumpos( -z, -2, 'Floor', 'Wrap' ); % -pi - z
            end; 
        end;          
    end;
end;