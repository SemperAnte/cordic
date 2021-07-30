function generateCordicLUT(fpathLUT)
% function generateCordicLUT(fpathLUT)
%
% generate file with LUT tables for atan and coefd
% include this file to CORDIC rtl project
% fpathLUT - path to LUT .vh file

% LUT table for arctangent
maxSizeLUT = 64;
atanLUTtotal = uint64(zeros(1, maxSizeLUT));
for i = 1 : maxSizeLUT
   atanDouble = atand(2 ^ (-(i - 1))) / 90;
   atanLUTtotal(i) = uint64(atanDouble * (2 ^ 62));
end

% LUT table for coefd
maxSizeLUT = 26; 
coefdDouble = 1;
coefdLUTtotal = uint64(zeros(1, maxSizeLUT));
for i = 0 : maxSizeLUT - 1
    coefdDouble = coefdDouble / sqrt(1 + 2 ^ (-2 * i));
    coefdLUTtotal(i + 1) = uint64(coefdDouble * (2 ^ 62));
end

% generate code file
fileID = fopen(fpathLUT, 'wt');
fprintf(fileID, '// long LUT tables for atan and coefd\n');
fprintf(fileID, '// Automatically generated with Matlab, do not edit\n');
fprintf(fileID, 'localparam logic [63 : 0] atanLUTlong [%i] = ''{\n', length(atanLUTtotal));
for i = 1 : length(atanLUTtotal)
    fprintf(fileID, '      64''d%i', atanLUTtotal(i));
    if (i == length(atanLUTtotal))
        fprintf(fileID, '};\n');
    else
        fprintf(fileID, ',\n');
    end
end
fprintf(fileID, '\n');
fprintf(fileID, 'localparam logic [63 : 0] coefdLUTlong [%i] = ''{\n', length(coefdLUTtotal));
for i = 1 : length(coefdLUTtotal)
    fprintf(fileID, '      64''d%i', coefdLUTtotal(i));
    if (i == length(coefdLUTtotal))
        fprintf(fileID, '};');
    else
        fprintf(fileID, ',\n');
    end
end
fclose(fileID);