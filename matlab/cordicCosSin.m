%--------------------------------------------------------------------------------
% Project:       dsplib
% Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
% History:
%    14.11.2016 - created
%    27.07.2021 - minor refactoring
%--------------------------------------------------------------------------------
% calculation of cosine/sine with CORDIC algorithm
%--------------------------------------------------------------------------------
clc; clear; close all;
addpath('func');

fpathSim = '..\sim\';
fpathModelsim = 'D:\CADS\Modelsim10_1c\win32\modelsim.exe';
fpathLUT = '..\rtl\cordicLUT.vh';

comparePlot = false; % compare CORDIC results with double precision
checkSlow = false;   % run slow version of algorithm and compare it with fast

CORDIC_TYPE = 1;  % for testbench - '0' for "SERIAL", '1' for "PARALLEL"
CORDIC_N    = 13; % number of iterations for CORDIC algorithm
PHI_WIDTH   = 18; % width of input angle phi (outputs is same width)  

% input angle phi
Npoints = 1.0e3;  % number of points for test
phiSign = 0;      % - '0' for unsigned format, '1' for signed format
phi = linspace(0, 1, Npoints);
phi = phi - phiSign * 0.5;
phi = fi(phi, phiSign, PHI_WIDTH, PHI_WIDTH);

if (~CORDIC_TYPE)
    fprintf('CORDIC_TYPE = "SERIAL"\n');
else
    fprintf('CORDIC_TYPE = "PARALLEL"\n');
end
fprintf('CORDIC_N  = %i\n', CORDIC_N);
fprintf('PHI_WIDTH = %i\n', PHI_WIDTH);

% generate LUT for atan/coefd
generateCordicLUT(fpathLUT);

% double precision
tic;
cosDouble = cos(double(phi) * 2 * pi);
sinDouble = sin(double(phi) * 2 * pi);
timeDouble = toc;
% CORDIC fast
tic;
[cosCordicFast, sinCordicFast] = cordicCosSinFast(phi, CORDIC_N);
timeCordicFast = toc;
fprintf('Estimated time for double      algorithm (with double ) = %f s.\n', timeDouble);
fprintf('Estimated time for CORDIC fast algorithm (with integer) = %f s.\n', timeCordicFast);

% plot compare
if (comparePlot)
    figure;
    subplot(2, 1, 1);
    plot(phi, cosDouble, phi, cosCordicFast);
    title('cos');
    legend('double built-in', 'CORDIC');
    grid on;
    subplot(2, 1, 2);
    plot(phi, abs(cosDouble - double(cosCordicFast)));
    title('abs error');
    line([phi(1) phi(end)], [eps(cosCordicFast) eps(cosCordicFast)], 'LineWidth', 2, 'Color', 'red');
    grid on;    

    figure;
    subplot(2, 1, 1);
    plot(phi, sinDouble, phi, sinCordicFast);
    title('sin');
    legend('double built-in', 'CORDIC');
    grid on;
    subplot(2, 1, 2);
    plot(phi, abs(sinDouble - double(sinCordicFast)));
    title('abs error');
    line([phi(1) phi(end)], [eps(sinCordicFast) eps(sinCordicFast)], 'LineWidth', 2, 'Color', 'red' );
    grid on;   
end

% check CORDIC slow version with fi objects if required
if (checkSlow)
    tic;
    [cosCordicSlow, sinCordicSlow] = cordicCosSinSlow(phi, CORDIC_N);
    timeCordicSlow = toc;
    fprintf('Estimated time for CORDIC slow algorithm (fi object   ) = %f s.\n', timeCordicSlow);
    if (any(cosCordicSlow ~= cosCordicFast))
        warning('Results of fast and slow cosine CORDIC algorithms are not equal.');
    end
    if (any(sinCordicSlow ~= sinCordicFast))
        warning('Results of fast and slow sine CORDIC algorithms are not equal.');
    end
end
%% create data for testbench
% file with parms
fileID = fopen([fpathSim 'parms.vh'], 'wt');
fprintf(fileID, '// Automatically generated with Matlab, do not edit\n' );
if (~CORDIC_TYPE)
    fprintf(fileID, 'localparam string CORDIC_TYPE = "SERIAL";\n');
else
    fprintf(fileID, 'localparam string CORDIC_TYPE = "PARALLEL";\n');
end
fprintf(fileID, 'localparam int N = %i,\n', CORDIC_N);
fprintf(fileID, '               PHI_WIDTH = %i;\n', PHI_WIDTH);
fclose(fileID);
% file with phi
txtFileWrite([fpathSim 'phi.txt'], phi, 'DEC');

%% autorun Modelsim
if (exist([fpathSim 'flag.txt'], 'file'))
    delete([fpathSim 'flag.txt']);
end
status = system([fpathModelsim ' -do ' fpathSim 'autoCosSin.do']);
pause on;
while (~exist([fpathSim 'flag.txt'], 'file')) % wait for flag file
    pause(1);
end

%% read data from testbench
NT = numerictype(cosCordicFast);
cosHdl = txtFileRead([fpathSim 'cos.txt'], NT, 'DEC');
sinHdl = txtFileRead([fpathSim 'sin.txt'], NT, 'DEC');

if (length(cosCordicFast) == length(cosHdl))
    fprintf('Length is equal = %i\n', length(cosCordicFast));
    x = 1 : length(cosCordicFast);    
elseif (length(cosCordicFast) > length(cosHdl))
    fprintf('Length is not equal, matlab = %i, hdl = %i.\n', length(cosCordicFast), length(cosHdl));
    x = 1 : length(cosHdl);
else
    fprintf('Length is not equal, matlab = %i, hdl = %i.\n', length(cosCordicFast), length(cosHdl));
    x = 1 : length(cosCordicFast);
end

fprintf('Number of errors for cos: %i.\n', sum(cosCordicFast(x) ~= cosHdl(x)));
fprintf('Number of errors for sin: %i.\n', sum(sinCordicFast(x) ~= sinHdl(x)));
if (true)
    figure;
    subplot(2, 1, 1);
    plot(phi(x), cosCordicFast(x), phi(x), cosHdl(x));
    title('cos');
    legend('matlab', 'hdl');
    grid on;    
    subplot( 2, 1, 2 );
    plot(phi(x), sinCordicFast(x), phi(x), sinHdl(x));
    title('sin');
    legend('matlab', 'hdl');
    grid on;
end