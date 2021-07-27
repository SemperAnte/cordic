function [data, dnan] = txtFileRead(fname, NT, dataRad, num)
% function [data, dnan] = txtFileRead(fname, NT, dataRad, num)
%
% data      - read data as fi object
% dnan      - vector with 1 for NaN in file
%
% fname     - file name
% NT        - numerictype object (i.e. numerictype(1, 13, 12))
% dataRad   - data radix ('BIN', 'HEX', 'UNS', 'DEC' (with sign))
% num       - number of elements in file for reading (pass it for reading 
%             until the EOF)

if (nargin < 3) % specify default radix
    dataRad = 'UNS';
end
if (nargin < 4) % read file until end
    num = Inf;
end

% read file to cells
fileID = fopen(fname, 'r');
N = 0;
ds = cell(1);
while ~feof(fileID)
    if (N < num)
        N = N + 1;
        ds{N} = fgetl(fileID);
    else
        break;
    end
end
if (~isinf(num) && N < num)
    warning('Only %i lines in file', N);
end
fclose(fileID);

% convert cells of string to fi object
data = fi(zeros(1, N), NT);
dnan = zeros(1, N);
switch dataRad
    case 'BIN'
        for i = 1 : N
            if (length(ds{i}) ~= NT.WordLength)
                warning('Wrong length of word, line: %i', i);
            end
            if (isstrprop(ds{i}, 'digit'))
                temp = fi(0, NT);
                temp.bin = ds{i};
                data(i) = temp;
            else
                warning('Not a number, line: %i', i);
                dnan(i) = 1;
            end        
        end
    case 'HEX'
        for i = 1 : N
            if (isstrprop(ds{i}, 'xdigit'))
                temp = fi(0, NT);
                temp.hex = ds{i};
                data(i) = temp;
            else
                warning('Not a number, line: %i', i);
                dnan(i) = 1;
            end
        end
    case 'UNS'
        for i = 1 : N
            if (isstrprop(ds{i}, 'digit'))
                temp = fi(0, NT);
                temp.dec = ds{i};
                data(i) = temp;
            else
                warning('Not a number, line: %i', i);
                dnan(i) = 1;
            end
        end
    case 'DEC'
        for i = 1 : N
            if (~isnan(str2double(ds{i})))
                temp = fi(0, NT);
                temp.int = str2double(ds{i});
                data(i) = temp;
            else
                warning('Not a number, line: %i', i);
                dnan(i) = 1;
            end
        end
    otherwise
        error('Not correct data radix!');
end