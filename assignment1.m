%% Bootstrap
% Load dataset
addpath('data');
[D, geometries] = loadDataset('./data/Buildings.xlsx');

% Start parallel pool
parfor i=1:1
    disp('Successfully started parallel pool.');
end

%% Task 1 [5 marks] (MBR calculation)
% (1) [1 mark] Write a program to compute the spatial extent of dataset D. 
%     The spatial extent of D is the MBR of all polygons in D. Report the 
%     MBR of D.
n = height(D);
minCord = ones(1, 2) * double(intmax("int32"));
maxCord = ones(1, 2) * double(intmin("int32"));
for i=1:n
    minCord = min([geometries{i}; minCord]);
    maxCord = max([geometries{i}; maxCord]);
end

% (2) [2 marks] Create dataset D% which adds an MBR column for the polygon 
%     in each record in D. Output the spreadsheet file for the new dataset 
%     D.
mbrs = zeros(n, 4);
mbrStrs = cell(n, 1);
parfor i=1:n
    currMinCord = min(geometries{i});
    currMaxCord = max(geometries{i});
    mbrs(i, :) = [currMinCord(1), currMinCord(2), ...
        currMaxCord(1), currMaxCord(2)];
    mbrStrs{i} = sprintf('RECTANGLE (%.7f, %.7f, %.7f, %.7f)', ...
        currMinCord(1), currMinCord(2), currMaxCord(1), currMaxCord(2));
end
D.MBR = mbrStrs;
writetable(D, './output/T1.2.xlsx');

% (3) [2 marks] Let n be the resolution for recursive decomposition of the 
%     space as defined by the spatial extent of D. What are the sizes (in 
%     cm by cm) of the smallest Peano cells for n = 16, 23 and 28 
%     respectively? Show your calculation steps. Please also discuss which 
%     resolution value is suitable for D.

% Calculate the real distance between 
%   (latitude 1, longitude 1), (latitude 2, longitude 2)
[mbrRealWidth, mbrRealHeight] = getRealSize(minCord, maxCord, 'cm');
mbrRealSize = [mbrRealWidth, mbrRealHeight];
fprintf("The size of the MBR: %f km x %f km\n", ...
    mbrRealWidth / 100000, mbrRealHeight / 100000);
resolutions = [16, 23, 28];
for i=1:length(resolutions)
    resolution = resolutions(i);
    mbrSmallestPeanoSize = mbrRealSize ./ (2^resolution);
    fprintf("When n = %d, the smallest Peano cells have a size %f cm x %f cm\n", ...
        resolution, mbrSmallestPeanoSize(1), ...
        mbrSmallestPeanoSize(2));
end

%% Task 2 [10 marks] (z-value indexing)
% (1) [6 mark] Write a program to generate the base-5 z-value for each 
%     polygon, for n = 16, 23 and 28 respectively. We use only one z-value 
%     for each object based on its MBR. Add three columns of z-values to D 
%     for these three different resolution levels. Output the spreadsheet 
%     file with the new columns.
[mbrRealWidth, mbrRealHeight] = getRealSize(minCord, maxCord, 'cm');
mbrRealSize = [mbrRealWidth, mbrRealHeight];
resolutions = [16, 23, 28];
for i=1:length(resolutions)
    resolution = resolutions(i);
    mbrPeanoSize = mbrRealSize ./ (2^resolution);
    zVals = cell(n, 1);
    parfor j=1:n
        % Find the center of the MBR
        mbrCenter = mean([mbrs(j, 1), mbrs(j, 2); mbrs(j, 3), mbrs(j, 4)]);
        % Real distance to the minCoor
        [mbrCenterRealWidth, mbrCenterRealHeight] = getRealSize(minCord, mbrCenter, 'cm');
        mbrCenterRealDist = [mbrCenterRealWidth, mbrCenterRealHeight];
        
        % Calculate the position on the grid
        centerPos = floor(mbrCenterRealDist ./ mbrPeanoSize);
        assert(all(centerPos >= 1));
        assert(all(centerPos <= 2^resolution));
        zVal = zValueBase5(resolution, centerPos);
        zVals{j} = zVal;
    end
    D.("zVals (n = " + string(resolution) + ")") = zVals;
end

% (2) [4 marks] For each object, compare the sizes of the Peano cells for 
%     the same object using the above 3 resolution numbers and analyze your 
%     findings. Remember that the Peano cells for an object should be as 
%     tight as possible. Your discussions should reveal insights about 
%     choosing the proper resolution level for an application. If you see 
%     any issues with using just one z-value for one object, discuss 
%     possible solutions.


