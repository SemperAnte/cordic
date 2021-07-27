function [magCordic, phCordic] = cordicMagPhFast(xCordic, yCordic, N)
% function [magCordic, phCordic] = cordicMagPhFast(xCordic, yCordic, N)
%
% calculate magnitude and phase with CORDIC algorithm
% accelerated version with casting fi to int64 and using parfor
% todo : add choices 'noph' 'noscl' 'nophnoscl', write c code 
%
% xCordic, yCordic - x, y coordinates, signed fi, must be same width
% N                - number of iterations

assert(xCordic.WordLength == yCordic.WordLength, 'X and Y coordinates must be same width');
XY_WDT = xCordic.WordLength;

xCordic = int64(storedInteger(xCordic));
yCordic = int64(storedInteger(yCordic));
% check sign of x, algorithm requires x >= 0
qrt = (xCordic < 0); % 2, 3 quarter
xCordic = abs(xCordic);

% lut table for arctangent
atanlut = int64(zeros(1, N));
for i = 1 : N
   atanlut(i) = atand(2 ^ (-(i - 1))) / 90 * 2 ^ 62; 
   atanlut(i) = bitshift(atanlut(i), -(62 - XY_WDT + 1));   
end
% coefficient of deformation value
coefd = 1;
for i = 0 : N - 1
    coefd = coefd / sqrt(1 + 2 ^ (-2 * i));
end
coefd = int64(coefd * 2 ^ 62);
coefd = bitshift(coefd, -(62 - XY_WDT + 1));

% debug info
if (false)
    for i = 1 : length(atanlut)
        fprintf('N%i : atan = %i\n', i, atanlut(i));
    end
    fprintf('coefd = %i\n', coefd);
end

L = length(xCordic);
magCordic = int64(zeros(1, L));
phCordic  = int64(zeros(1, L));
scl = true(1, L); % index that need scaling on coefd
% CORDIC algorithm
parfor i = 1 : L
    x = xCordic(i);
    y = yCordic(i);
    z = int64(0);    
    % if y = 0, algorithm does not need
    if (y == 0)
        magCordic(i) = x;
        phCordic(i) = 0;
        scl(i) = false; % do not need scaling
    else % CORDIC
        for j = 0 : N - 1
            xsh = bitshift(x, -j);
            ysh = bitshift(y, -j);
            % check sign
            if (y < 0) 
                x = x - ysh;
                y = y + xsh;
                z = z - atanlut(j + 1);
            else
                x = x + ysh;
                y = y - xsh;
                z = z + atanlut(j + 1);
            end
        end
        magCordic(i) = x;
        phCordic(i) = z;      
    end
end

% chek sign of magnitude
magCordic(magCordic < 0) = 0;
% cast int64 to fi
magCordic = ufi(double(magCordic) / 2 ^ (XY_WDT - 1), XY_WDT + 1, XY_WDT - 1);
coefd = ufi(double(coefd) / 2 ^ (XY_WDT - 1), XY_WDT - 1, XY_WDT - 1);
F = fimath('ProductMode', 'SpecifyPrecision', ...
           'ProductWordLength', XY_WDT + 1, ...
           'ProductFractionLength', XY_WDT - 1, ...
           'RoundingMethod', 'Floor');
magCordic(scl) = mpy(F, magCordic(scl), coefd);
magCordic = ufi(magCordic, XY_WDT, XY_WDT - 1);
     
% saturate phase [ -pi/2 pi/2 ]
phCordic(phCordic >  2 ^ (XY_WDT - 1)) =  2 ^ (XY_WDT - 1);
phCordic(phCordic < -2 ^ (XY_WDT - 1)) = -2 ^ (XY_WDT - 1); 
% calc phase depending on quarter
ind = qrt & (phCordic >= 0);
phCordic(ind) = 2 ^ XY_WDT - phCordic(ind);   % pi - z  
ind = qrt & phCordic < 0;
phCordic(ind) = - 2 ^ XY_WDT - phCordic(ind); % -pi - z
phCordic = sfi(double(phCordic) / 2 ^ (XY_WDT - 1), XY_WDT + 2, XY_WDT - 1);
