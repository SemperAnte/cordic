function txtFileWrite( fname, data, dataRad, num )
% function txtFileWrite( fname, data, dataRad, num )
%
% fname    - file name
% data     - data, fi object (or double for 'DBL' dataRad)
% dataRad  - data radix ('BIN', 'HEX', 'UNS', 'DEC'(with sign), 'DBL')
% num      - number of elements in file (if needed add zeros or cut elements)

% specify default radix
if ( nargin < 3 )
    dataRad = 'UNS';            
end;
% specify number of elements
if ( nargin > 3 )
    if ( num > length( data ) ) % adding zeros
        data( end + 1 : num ) = 0;
    else                    % cutting
        data = data( 1 : num );
    end;
else
    num = length( data );
end;

% data string
ds = cell( 1, num );
switch dataRad
    case 'BIN'
        for i = 1 : num
            t = data( i );
            ds{ i } = t.bin;
        end;
    case 'HEX'
        for i = 1 : num
            t = data( i );
            ds{ i } = t.hex;
        end;
    case 'UNS'
        for i = 1 : num
            t = data( i );
            ds{ i } = t.dec;
        end;
    case 'DEC'
        for i = 1 : num
            t = data( i );
            ds{ i } = num2str( t.int, '%i' );
        end;
    case 'DBL'
        for i = 1 : num
            ds{ i } = num2str( data( i ) );
        end;
    otherwise
        error( 'Not correct data radix!' );
end;

fileID = fopen( fname, 'wt' );
for i = 1 : num
    fprintf( fileID, ds{ i } );   
    fprintf( fileID, '\n' );
end;
fclose( fileID );