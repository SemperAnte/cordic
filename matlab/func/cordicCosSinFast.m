function [cosCordic, sinCordic] = cordicCosSinFast(phi, N)
% function [cosCordic, sinCordic] = cordicCosSinFast(phi, N)
%
% calculate cosine and sine with CORDIC algorithm
% accelerated version with casting fi to int64 and using parfor
% todo : write c code
%
% phi - input angle: unsigned fi [  0(0000..) ... 2*pi(1111..)) or
%                      signed fi [-pi(1000..) ...   pi(0111..))
% N   - number of iterations

PHI_WDT = phi.WordLength;
% convert to unsigned
phi = reinterpretcast(phi, numerictype(0, PHI_WDT, PHI_WDT));
phi = int64(storedInteger(phi));
% cast angle from 0 ... 2*pi to pi/2 ... -pi/2 
% 2, 3 quarter
qrt = (phi >= 2 ^ (PHI_WDT - 2)) & (phi < 3 * 2 ^ (PHI_WDT - 2));
phi(qrt) = 2 ^ (PHI_WDT - 1) - phi(qrt);
% 4 quarter
ind = phi >=  3 * 2 ^ (PHI_WDT - 2);
phi(ind) = phi(ind) - 2 ^ PHI_WDT;

% lut table for arctangent
atanlut = int64(zeros(1, N));
for i = 1 : N
   atanlut(i) = atand(2 ^ (-(i - 1))) / 90 * 2 ^ 62; 
   atanlut(i) = bitshift(atanlut(i), -(62 - PHI_WDT + 2));   
end
% coefficient of deformation value
coefd = 1;
for i = 0 : N - 1
    coefd = coefd / sqrt(1 + 2^(-2 * i));
end
coefd = int64(coefd * 2 ^ 62);
coefd = bitshift(coefd, -(62 - PHI_WDT + 2));

% debug info
if (false)
    for i = 1 : length(atanlut)
        fprintf('N%i : atan = %i\n', i, atanlut(i));
    end
    fprintf('coefd = %i\n', coefd);
end

L = length(phi);
cosCordic = int64(zeros(1, L));
sinCordic = int64(zeros(1, L));
% CORDIC algorithm
parfor i = 1 : L
    x = coefd;
    y = int64(0);
    z = phi(i);
    % iterations of algorithm
    for j = 0 : N - 1
        xsh = bitshift(x, -j);
        ysh = bitshift(y, -j);
        if (z >= 0)
            x = x - ysh;
            y = y + xsh;
            z = z - atanlut(j + 1);
        else
            x = x + ysh;
            y = y - xsh;
            z = z + atanlut(j + 1);
        end
    end
    cosCordic(i) = x; 
    sinCordic(i) = y;           
end

% for 2,3 quarter change sign of cosine
cosCordic(qrt) = - cosCordic(qrt);

% limit outputs
cosCordic(cosCordic >   2 ^ (PHI_WDT - 2)) =   2 ^ (PHI_WDT - 2);
cosCordic(cosCordic < - 2 ^ (PHI_WDT - 2)) = - 2 ^ (PHI_WDT - 2);
sinCordic(sinCordic >   2 ^ (PHI_WDT - 2)) =   2 ^ (PHI_WDT - 2);
sinCordic(sinCordic < - 2 ^ (PHI_WDT - 2)) = - 2 ^ (PHI_WDT - 2);

% cast int64 to fi
T = numerictype(1, PHI_WDT, PHI_WDT - 2);
cosCordic = fi(double(cosCordic) / 2 ^ (PHI_WDT - 2), T);
sinCordic = fi(double(sinCordic) / 2 ^ (PHI_WDT - 2), T);