function [magCordic, phCordic] = cordicMagPhSlow(xCordic, yCordic, N)
% function [magCordic, phCordic] = cordicMagPhSlow(xCordic, yCordic, N)
%
% calculate magnitude and phase with CORDIC algorithm
% slow version with fixed point for hdl code development
%
% xCordic, yCordic  - x, y coordinate, signed fi, must be same width
% N                 - number of iterations

assert(xCordic.WordLength == yCordic.WordLength, 'X and Y coordinates must be same width');
XY_WDT = xCordic.WordLength;
xCordic = reinterpretcast(xCordic, numerictype(1, XY_WDT, XY_WDT - 1));
yCordic = reinterpretcast(yCordic, numerictype(1, XY_WDT, XY_WDT - 1));

% lut table for arctangent
atanlut = int64(zeros(1, N));
for i = 1 : N
   atanlut(i) = atand(2 ^ (-(i - 1))) / 90 * 2 ^ 62; 
   atanlut(i) = bitshift(atanlut(i), -(62 - XY_WDT + 1));   
end
atanlut = fi(atanlut, numerictype(0, XY_WDT - 1, 0));
atanlut = reinterpretcast(atanlut, numerictype(0, XY_WDT - 1, XY_WDT - 1)); 
% coefficient of deformation value
coefd = 1;
for i = 0 : N - 1
    coefd = coefd / sqrt(1 + 2 ^ (-2 * i));
end
coefd = int64(coefd * 2 ^ 62);
coefd = bitshift(coefd, -(62 - XY_WDT + 1));
coefd = fi(coefd, numerictype(0, XY_WDT - 1, 0));
coefd = reinterpretcast(coefd, numerictype(0, XY_WDT - 1, XY_WDT - 1));

% debug info
if (false)
    for i = 1 : length(atanlut)
        fprintf('N%i : atan = %i\n', i, storedInteger(atanlut(i)));
    end
    fprintf('coefd = %i\n', storedInteger(coefd));
end

L = length(xCordic);
T = numerictype(1, XY_WDT + 2, XY_WDT - 1);
F = fimath('ProductMode', 'SpecifyPrecision',...
           'ProductWordLength', XY_WDT + 1, ...
           'ProductFractionLength', XY_WDT - 1, ...
           'RoundingMethod', 'Floor');
magCordic = fi(zeros(1, L), 0, XY_WDT, XY_WDT - 1);
phCordic  = fi(ones(1, L), T);
% CORDIC algorithm
x   = fi(0, T);
y   = fi(0, T);
z   = fi(0, T);
for i = 1 : L
    x(:) = xCordic(i);
    y(:) = yCordic(i);
    z(:) = 0;
    % check sign of x, algorithm requires x >= 0
    if (x < 0)
        qrt = true;  % 2, 3 quarter
        x(:) = abs(x);        
    else
        qrt = false; % 1, 4 quarter
    end
    % if y = 0, algorithm does not need
    if (y == 0)
        magCordic(i) = x;
        if (qrt == 0)
            phCordic(i) = 0;
        else % x < 0
            phCordic(i) = 2; % pi
        end
    else % y != 0
        % iterations of algorithm
        for j = 0 : N - 1
            xsh = bitshift(x, -j);
            ysh = bitshift(y, -j);
            % check sign
            if (y < 0) 
                x = accumneg(x, ysh, 'Floor', 'Wrap');
                y = accumpos(y, xsh, 'Floor', 'Wrap');
                z = accumneg(z, atanlut(j + 1), 'Floor', 'Wrap');
            else
                x = accumpos(x, ysh, 'Floor', 'Wrap');
                y = accumneg(y, xsh, 'Floor', 'Wrap');
                z = accumpos(z, atanlut(j + 1), 'Floor', 'Wrap');
            end
        end
        % multiply magnitude on coefd
        if (x >= 0)
            magCordic(i) = mpy(F, x, coefd);
        else % x < 0 - set magnitude = 0
            magCordic(i) = 0;
        end
        % saturate phase [-pi/2 pi/2]
        if (z > 1)
            z(:) = 1;
        elseif (z < -1)
            z(:) = -1;
        end
        % calc phase depending on quarter
        if (qrt == false) % 1, 4 quarter    
            phCordic(i) = z;
        else              % 2, 3 quarter
            if (z >= 0)
                phCordic(i) = accumpos(-z,  2, 'Floor', 'Wrap'); % pi - z           
            else % z < 0
                phCordic(i) = accumpos(-z, -2, 'Floor', 'Wrap'); % -pi - z
            end
        end       
    end
end