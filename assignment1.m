%% Bootstrap
% Load dataset
addpath('data');
[D, geometries] = loadDataset('./data/Buildings.xlsx');

% Start parallel pool
parfor i=1:1
    disp('Successfully started parallel pool.');
end

% Length unit
unit = 'cm';

%% Task 1 [5 marks] (MBR calculation)
% (1) [1 mark] Write a program to compute the spatial extent of dataset D. 
%     The spatial extent of D is the MBR of all polygons in D. Report the 
%     MBR of D.
n = height(D);
spatialExtent = getSpatialExtent(geometries);

% (2) [2 marks] Create dataset D' which adds an MBR column for the polygon 
%     in each record in D. Output the spreadsheet file for the new dataset 
%     D.
mbrs = getMBRs(geometries);
mbrStrs = cell(n, 1);
for i=1:n
    mbr = mbrs(i, :);
    mbrStrs{i} = sprintf('RECTANGLE (%.7f, %.7f, %.7f, %.7f)', ...
        mbr(1), mbr(2), mbr(3), mbr(4));
end
D.MBR = mbrStrs;
writetable(D, './output/T1.2.xlsx');

% (3) [2 marks] Let n be the resolution for recursive decomposition of the 
%     space as defined by the spatial extent of D. What are the sizes (in 
%     cm by cm) of the smallest Peano cells for n = 12, 16 and 20 
%     respectively? Show your calculation steps. Please also discuss which 
%     resolution value is suitable for D.

% Calculate the real distance between the base of D
spatialExtentGeoSize = getSpatialExtentGeoSize(spatialExtent, unit);
fprintf("The size of the MBR: %f km x %f km\n", ...
    spatialExtentGeoSize(1) / 100000, spatialExtentGeoSize(2) / 100000);
resolutions = [12, 16, 20];
for i=1:length(resolutions)
    resolution = resolutions(i);
    peanoCellGeoSize = getPeanoCellGeoSize(spatialExtent, resolution, unit);
    fprintf("When n = %d, the smallest Peano cells have a size %f cm x %f cm\n", ...
        resolution, peanoCellGeoSize(1), ...
        peanoCellGeoSize(2));
end

%% Task 2 [10 marks] (z-value indexing)
% (1) [6 mark] Write a program to generate the base-5 z-value for each 
%     polygon, for n = 12, 16 and 20 respectively. We use only one z-value 
%     for each object based on its MBR. Add three columns of z-values to D 
%     for these three different resolution levels. Output the spreadsheet 
%     file with the new columns.
resolutions = [12, 16, 20];
for i=1:length(resolutions)
    resolution = resolutions(i);
    peanoCellGeoSize = getPeanoCellGeoSize(spatialExtent, resolution, unit);
    zVals = cell(n, 1);
    parfor j=1:n
        mbr = mbrs(j, :);

        % Find the four vertex of the MBR
        topRight = mbr([3, 4]);
        bottomLeft = mbr([1, 2]);

        % Get the coordinate on grid
        topRightCoor = getCoordinateOnGrid(topRight, spatialExtent(1:2), ...
            peanoCellGeoSize, unit);
        bottomLeftCoor = getCoordinateOnGrid(bottomLeft, spatialExtent(1:2), ...
            peanoCellGeoSize, unit);

        topRightZVal = zValueBase5(resolution, topRightCoor);
        bottomLeftZVal = zValueBase5(resolution, bottomLeftCoor);
        zVal = longestCommonPrefix(bottomLeftZVal, topRightZVal);
        zVal = padString(zVal, resolution, '0');
        zVals{j} = zVal;
    end
    D.("zVals (n = " + string(resolution) + ")") = zVals;
end
writetable(D, './output/T2.1.xlsx');

% (2) [4 marks] For each object, compare the sizes of the Peano cells for 
%     the same object using the above 3 resolution numbers and analyze your 
%     findings. Remember that the Peano cells for an object should be as 
%     tight as possible. Your discussions should reveal insights about 
%     choosing the proper resolution level for an application. If you see 
%     any issues with using just one z-value for one object, discuss 
%     possible solutions.
for i=1:length(resolutions)
    resolution = resolutions(i);
    peanoCellGeoSize = getPeanoCellGeoSize(spatialExtent, resolution, unit);
    zVals = D.("zVals (n = " + string(resolution) + ")");
    realWidths = cell(n, 1);
    realHeights = cell(n, 1);
    for j=1:length(zVals)
        % Count the number of zeros
        zVal = zVals{j};
        numZeros = 0;
        assert(isa(class(zVal), 'char') == 1);
        for p=length(zVal):-1:1
            if zVal(p) ~= '0'
                break;
            end
            numZeros = numZeros + 1;
        end
        numRows = 2^numZeros;
        % Convert cm to m
        realWidths{j} = peanoCellGeoSize(1) * numRows / 100;
        realHeights{j} = peanoCellGeoSize(2) * numRows / 100;
    end
    D.("Peano cells width (n = " + string(resolution) + ") m") = realWidths;
    D.("Peano cells height (n = " + string(resolution) + ") m") = realHeights;
end
writetable(D, './output/T2.2.xlsx');

%% Task 3 [10 marks] (window query processing)
% A window query with a given query rectangle represented as 
% Q = {(x_low, y_low), (x_high, y_high)} returns the number of objects 
% inside Q.
% (1) [7 marks] Write a program to perform window queries using two 
%     approaches: (i) by exhaustively checking every object in the dataset; 
%     and (ii) by using z-values you generate in Task 2 for the above three 
%     n values.
query = getRandomQueries(1, spatialExtent);

% Exhaustive search
windowQueryTable = D(:, {'id'});
windowQueryTable.mbrs = mbrs;
ids = runWindowQuery(query, windowQueryTable);

% With z-value
resolution = 20;
windowQueryWithZValueTable = D(:, {'id'});
windowQueryWithZValueTable.mbrs = mbrs;
windowQueryWithZValueTable.zVals = D.("zVals (n = " + string(resolution) + ")");
windowQueryWithZValueTable = sortrows(windowQueryWithZValueTable, 'zVals');

idsZVal = runWindowQueryWithZValue(query, windowQueryWithZValueTable, spatialExtent, resolution, unit);

% (2) [3 mark] Use 20 randomly generated window queries of different sizes 
%     at different locations to search using the programs you developed 
%     above, to report (i) the number of objects inside each query window, 
%     (ii) the number of objects searched for each query for using no 
%     z-values (i.e., exhaustive search) and using z-values obtained using 
%     different resolution numbers.
% Generate random queries
numRandQueries = 20;
queries = getRandomQueries(numRandQueries, spatialExtent);
for i=1:length(resolutions)
    resolution = resolutions(i);
    fprintf("\nCurrent resolution: n = %d\n", resolution);
    for queryId=1:numRandQueries
        query = queries(queryId, :);
        fprintf("(%f, %f), (%f, %f) & ", query(1), query(2), query(3), query(4));

        % Run window query with exhaustive search
        [ids, qryStat] = runWindowQuery(query, windowQueryTable);
        fprintf("%d & %d & ", length(ids), qryStat.compareCount);

        % Run window query with z-values
        [idsZVal, qryStatZVal] = runWindowQueryWithZValue(query, windowQueryWithZValueTable, spatialExtent, resolution, unit);
        fprintf("%d \\\\\n", qryStatZVal.compareCount);

        assert(length(ids) == length(idsZVal));
    end
end


%% Tests
% Ensure the correctness of the windows query with z-value by large using
% a large number of random tests
numTestQueries = 20000;
testQueries = getRandomQueries(numTestQueries, spatialExtent);
m = length(testQueries);
parfor queryId=1:numTestQueries
    fprintf("Current query id: %d\n", queryId);
    query = testQueries(queryId, :);
    
    % Run window query with exhaustive search
    [ids, qryStat] = runWindowQuery(query, windowQueryTable);

    % Run window query with z-values
    [idsZVal, qryStatZVal] = runWindowQueryWithZValue(query, windowQueryWithZValueTable, spatialExtent, resolution, unit);

    assert(length(ids) == length(idsZVal));
end

