%--------------------------------------------------------------------------------
% Project:       dsplib
% Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
% History:
%    14.11.2016 - created
%    27.07.2021 - minor refactoring
%--------------------------------------------------------------------------------
% calculation of magnitude/phase with CORDIC algorithm
%--------------------------------------------------------------------------------
clc; clear; close all;
addpath('func');

fpathSim = '..\sim\';
fpathModelsim  = 'D:\CADS\Modelsim10_1c\win32\modelsim.exe';
fpathLUT = '..\rtl\cordicLUT.vh';

CORDIC_TYPE = "SERIAL";  % for testbench - "SERIAL" or "PARALLEL"
CORDIC_N    = 13; % number of iterations for CORDIC algorithm
XY_WIDTH    = 18; % width of x/y inputs

comparePlot = false; % compare CORDIC results with double precision
checkSlow = false;   % run slow version of algorithm and compare it with fast

% x/y inputs
x = -1 : 1e-2 : 1;
y = -1 : 1e-2 : 1;
x = repmat(x', 1, length(y))';
x = x(:)';
y = repmat(y, 1, length(x) / length(y));
x = sfi(x, XY_WIDTH, XY_WIDTH - 1);
y = sfi(y, XY_WIDTH, XY_WIDTH - 1);

fprintf('CORDIC_TYPE = "%s"\n', CORDIC_TYPE);
fprintf('CORDIC_N = %i\n', CORDIC_N);
fprintf('XY_WIDTH = %i\n', XY_WIDTH);

% generate LUT for atan/coefd
generateCordicLUT(fpathLUT);

% double precision
tic;
magDouble = abs(double(x) + 1j * double(y));
phDouble  = angle(double(x) + 1j * double(y)) / (pi / 2);
timeDouble = toc;
% cordic fast
tic;
[magCordicFast, phCordicFast] = cordicMagPhFast(x, y, CORDIC_N);
timeCordicFast = toc;
fprintf('Estimated time for double      algorithm (with double ) = %f s.\n', timeDouble);
fprintf('Estimated time for CORDIC fast algorithm (with integer) = %f s.\n', timeCordicFast);
% plot compare
if (comparePlot)
    figure;
    subplot(2, 1, 1);
    plot(1 : length(magDouble), magDouble, 1 : length(magCordicFast), magCordicFast);
    title('magnitude');
    legend('double built-in', 'CORDIC' );
    grid on;
    subplot(2, 1, 2);
    plot(abs(magDouble - double(magCordicFast)));
    title('abs error');
    line([1 length(magCordicFast)], [eps(magCordicFast) eps(magCordicFast)], 'LineWidth', 2, 'Color', 'red');
    grid on;    

    figure;
    subplot(2, 1, 1);
    plot(1 : length(phDouble), phDouble, 1 : length(phCordicFast), phCordicFast);
    title('phase');
    legend('double built-in', 'CORDIC');
    grid on;
    subplot(2, 1, 2);
    plot(abs(phDouble - double(phCordicFast)));
    title('abs error');
    line([1 length(phCordicFast)], [eps(phCordicFast) eps(phCordicFast)], 'LineWidth', 2, 'Color', 'red');
    grid on;   
end

% check CORDIC slow version with fi objects if required
if (checkSlow)
    tic;
    [magCordicSlow, phCordicSlow] = cordicMagPhSlow(x , y, CORDIC_N);
    timeSlow = toc;
    fprintf('Estimated time for CORDIC slow algorithm (fi object   ) = %f s.\n', timeSlow);
    if (any(magCordicSlow ~= magCordicFast))
        warning( 'Outputs of fast and slow magnitude CORDIC algorithms are not equal.');
    end
    if (any(phCordicSlow ~= phCordicFast))
        warning( 'Outputs of fast and slow phase CORDIC algorithms are not equal.');
    end
end

%% create data for testbench
% file with parms
fileID = fopen([fpathSim 'parms.vh'], 'wt');
fprintf(fileID, '// Automatically generated with Matlab, do not edit\n');
fprintf(fileID, 'localparam string CORDIC_TYPE = "%s";\n', CORDIC_TYPE);
fprintf(fileID, 'localparam int N        = %i,\n', CORDIC_N);
fprintf(fileID, '               XY_WIDTH = %i;\n', XY_WIDTH);
fclose(fileID);
% files with x/y
txtFileWrite([fpathSim 'xin.txt'], x, 'DEC');
txtFileWrite([fpathSim 'yin.txt'], y, 'DEC');
%% autorun Modelsim
if (exist([fpathSim 'flag.txt'], 'file'))
     delete([fpathSim 'flag.txt']);
end
status = system([fpathModelsim ' -do ' fpathSim 'autoMagPh.do']);
pause on;
while (~exist([fpathSim 'flag.txt'], 'file')) % wait for flag file
    pause(1);
end

%% read data from testbench
NT = numerictype(magCordicFast);
magHdl = txtFileRead([fpathSim 'mag.txt'], NT, 'DEC');
NT = numerictype(phCordicFast);
phHdl  = txtFileRead([fpathSim 'ph.txt'], NT, 'DEC');

if (length(magCordicFast) == length(magHdl))
    fprintf('Length is equal = %i.\n', length(magCordicFast));
    x = 1 : length(magCordicFast);    
elseif (length(magCordicFast) > length(magHdl))
    fprintf('Length is not equal, matlab = %i, hdl = %i.\n', length(magCordicFast), length(magHdl));
    x = 1 : length(magHdl);
else
    fprintf('Length is not equal, matlab = %i, hdl = %i.\n', length(magCordicFast), length(magHdl));
    x = 1 : length(magCordicFast);
end

fprintf('Number of errors for mag: %i.\n', sum(magCordicFast(x) ~= magHdl(x)));
fprintf('Number of errors for ph : %i.\n', sum(phCordicFast(x) ~= phHdl(x)));
if (true)
    figure;
    subplot(2, 1, 1);
    plot(x, magCordicFast(x), x, magHdl(x));
    title('mag');
    legend('matlab', 'hdl');
    grid on;    
    subplot(2, 1, 2);
    plot(x, phCordicFast(x), x, phHdl(x));
    title('ph');
    legend('matlab', 'hdl');
    grid on; 
end