function [cosCordic, sinCordic] = cordicCosSinSlow(phi, N)
% function [cosCordic, sinCordic] = cordicCosSinSlow(phi, N)
%
% calculate cosine and sin with CORDIC algorithm
% slow version with fixed point for hdl code development
%
% phi - input angle: unsigned fi [  0(0000..) ... 2*pi(1111..)) or
%                      signed fi [-pi(1000..) ...   pi(0111..))
% N   - number of iterations

PHI_WIDTH = phi.WordLength;
% convert to unsigned
phi = reinterpretcast(phi, numerictype(0, PHI_WIDTH, PHI_WIDTH));

% lut table for arctangent
atanlut = int64(zeros(1, N));
for i = 1 : N
   atanlut(i) = atand(2 ^ (-(i - 1))) / 90 * 2 ^ 62; 
   atanlut(i) = bitshift(atanlut(i), -(62 - PHI_WIDTH + 2));   
end
atanlut = fi(atanlut, numerictype(0, PHI_WIDTH - 2, 0));
atanlut = reinterpretcast(atanlut, numerictype(0, PHI_WIDTH - 2, PHI_WIDTH - 2)); 
% coefficient of deformation value
coefd = 1;
for i = 0 : N - 1
    coefd = coefd / sqrt(1 + 2 ^ (-2 * i));
end
coefd = int64(coefd * 2 ^ 62);
coefd = bitshift(coefd, -(62 - PHI_WIDTH + 2));
coefd = fi(coefd, numerictype(0, PHI_WIDTH - 2, 0));
coefd = reinterpretcast(coefd, numerictype(0, PHI_WIDTH - 2, PHI_WIDTH - 2));

L = length(phi);
T = numerictype(1, PHI_WIDTH, PHI_WIDTH - 2);
cosCordic = fi(zeros(1, L), T);
sinCordic = fi(zeros(1, L), T);
% CORDIC algorithm
x = fi(0, T);
y = fi(0, T);
for i = 1 : L
    x(:) = coefd;
    y(:) = 0;
    % cast phi angle from 0...2*pi to -pi/2...pi/2
    if (bitget(phi(i), PHI_WIDTH) == bitget(phi(i), PHI_WIDTH - 1)) % 1, 4 quarter (00 or 11)         
        z = reinterpretcast(phi(i), T);    
        qrt = false;
    else % 2, 3 quarter (01 or 10)    
        z = reinterpretcast(phi(i), T);
        z = accumneg(z, eps(z), 'Floor', 'Wrap');
        % first bit and inverted others
        z = reinterpretcast(bitconcat(bitget(z, PHI_WIDTH), bitcmp(bitsliceget(z, PHI_WIDTH - 1, 1))), T);
        qrt = true;
    end
    % iterations of algorithm
    for j = 0 : N - 1
        xsh = bitshift(x, -j);
        ysh = bitshift(y, -j);
        if (z >= 0)
            x = accumneg(x, ysh, 'Floor', 'Wrap');
            y = accumpos(y, xsh, 'Floor', 'Wrap');
            z = accumneg(z, atanlut(j + 1), 'Floor', 'Wrap');
        else
            x = accumpos(x, ysh, 'Floor', 'Wrap');
            y = accumneg(y, xsh, 'Floor', 'Wrap');
            z = accumpos(z, atanlut(j + 1), 'Floor', 'Wrap');
        end
    end
    % limit outputs
    if (x >= 1)
        x(:) = 1;
    elseif (x < -1)
        x(:) = -1;
    end
    if (y >= 1)
        y(:) = 1;
    elseif (y < -1)
        y(:) = -1;
    end
    % for 2 and 3 quarter change sign of cosine
    if (qrt)
        x = -x;
    end
    cosCordic(i) = x; 
    sinCordic(i) = y;           
end