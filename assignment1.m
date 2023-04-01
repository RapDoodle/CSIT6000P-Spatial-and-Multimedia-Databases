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
minCoord = ones(1, 2) * double(intmax("int32"));
maxCoord = ones(1, 2) * double(intmin("int32"));
for i=1:n
    minCoord = min([geometries{i}; minCoord]);
    maxCoord = max([geometries{i}; maxCoord]);
end
spatialExtent = [minCoord, maxCoord];

% (2) [2 marks] Create dataset D' which adds an MBR column for the polygon 
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
        topLeft = mbr([1, 4]);
        topRight = mbr([3, 4]);
        bottomLeft = mbr([1, 2]);
        bottomRight = mbr([3, 2]);

        % Get the coordinate on grid
        topLeftCoor = getCoordinateOnGrid(topLeft, minCoord, ...
            peanoCellGeoSize, unit);
        topRightCoor = getCoordinateOnGrid(topRight, minCoord, ...
            peanoCellGeoSize, unit);
        bottomLeftCoor = getCoordinateOnGrid(bottomLeft, minCoord, ...
            peanoCellGeoSize, unit);
        bottomRightCoor = getCoordinateOnGrid(bottomRight, minCoord, ...
            peanoCellGeoSize, unit);

        assert(all(topLeftCoor >= 1));
        assert(all(topLeftCoor <= 2^resolution));
        assert(all(topRightCoor >= 1));
        assert(all(topRightCoor <= 2^resolution));
        assert(all(bottomLeftCoor >= 1));
        assert(all(bottomLeftCoor <= 2^resolution));
        assert(all(bottomRightCoor >= 1));
        assert(all(bottomRightCoor <= 2^resolution));

        topLeftZVal = zValueBase5(resolution, topLeftCoor);
        topRightZVal = zValueBase5(resolution, topRightCoor);
        bottomLeftZVal = zValueBase5(resolution, bottomLeftCoor);
        bottomRightZVal = zValueBase5(resolution, bottomRightCoor);
        zVal = longestCommonPrefix(topLeftZVal, topRightZVal, bottomLeftZVal, bottomRightZVal);
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
query = [((maxCoord(1) - minCoord(1)) * 0.25) + minCoord(1), ...
         ((maxCoord(2) - minCoord(2)) * 0.25) + minCoord(2), ...
         ((maxCoord(1) - minCoord(1)) * 0.75) + minCoord(1), ...
         ((maxCoord(2) - minCoord(2)) * 0.75) + minCoord(2)];

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

peanoCellGeoSize = getPeanoCellGeoSize(spatialExtent, resolution, unit);
queryMinCoord = getCoordinateOnGrid(query(1:2), minCoord, peanoCellGeoSize, unit);
queryMaxCoord = getCoordinateOnGrid(query(3:4), minCoord, peanoCellGeoSize, unit);
minZVal = zValueBase5(resolution, queryMinCoord);
maxZVal = zValueBase5(resolution, queryMaxCoord);
minZVal = padString(longestCommonPrefix(minZVal, maxZVal), resolution, '0');

idsZVal = runWindowQueryWithZValue(query, minZVal, maxZVal, windowQueryWithZValueTable);

% (2) [3 mark] Use 20 randomly generated window queries of different sizes 
%     at different locations to search using the programs you developed 
%     above, to report (i) the number of objects inside each query window, 
%     (ii) the number of objects searched for each query for using no 
%     z-values (i.e., exhaustive search) and using z-values obtained using 
%     different resolution numbers.
% Generate random queries
numRandQueries = 20;
queries = zeros(numRandQueries, 4);
for queryId=1:numRandQueries
    randCoords = rand(2, 2);
    randMinCoord = min(randCoords);
    randMaxCoord = max(randCoords);
    query = [((maxCoord(1) - minCoord(1)) * randMinCoord(1)) + minCoord(1), ...
             ((maxCoord(2) - minCoord(2)) * randMinCoord(2)) + minCoord(2), ...
             ((maxCoord(1) - minCoord(1)) * randMaxCoord(1)) + minCoord(1), ...
             ((maxCoord(2) - minCoord(2)) * randMaxCoord(2)) + minCoord(2)];
    queries(queryId, :) = query;
end
for i=1:length(resolutions)
    resolution = resolutions(i);
    fprintf("\nCurrent resolution: n = %d\n", resolution);
    for queryId=1:numRandQueries
        query = queries(queryId, :);
        fprintf("(%f, %f), (%f, %f) & ", query(1), query(2), query(3), query(4));
        % Run window query with exhaustive search
        [ids, qryStat] = runWindowQuery(query, windowQueryTable);
        fprintf("%d & %d & ", length(ids), qryStat.compareCount);
    
        peanoCellGeoSize = getPeanoCellGeoSize(spatialExtent, resolution, unit);
        queryMinCoord = getCoordinateOnGrid(query(1:2), minCoord, peanoCellGeoSize, unit);
        queryMaxCoord = getCoordinateOnGrid(query(3:4), minCoord, peanoCellGeoSize, unit);
        minZVal = zValueBase5(resolution, queryMinCoord);
        maxZVal = zValueBase5(resolution, queryMaxCoord);
        minZVal = padString(longestCommonPrefix(minZVal, maxZVal), resolution, '0');
        
        % Run window query with z-values
        [idsZVal, qryStatZVal] = runWindowQueryWithZValue(query, minZVal, maxZVal, windowQueryWithZValueTable);
        fprintf("%d \\\\\n", qryStatZVal.compareCount);
    
        assert(length(ids) == length(idsZVal));
    end
end


%% Tests
% Ensure the correctness of the windows query with z-value by large using
% a large number of random tests
parfor queryId=1:20000
    fprintf("Current query id: %d\n", queryId);
    randCoords = rand(2, 2);
    randMinCoord = min(randCoords);
    randMaxCoord = max(randCoords);
    query = [((maxCoord(1) - minCoord(1)) * randMinCoord(1)) + minCoord(1), ...
             ((maxCoord(2) - minCoord(2)) * randMinCoord(2)) + minCoord(2), ...
             ((maxCoord(1) - minCoord(1)) * randMaxCoord(1)) + minCoord(1), ...
             ((maxCoord(2) - minCoord(2)) * randMaxCoord(2)) + minCoord(2)];

    ids = runWindowQuery(query, windowQueryTable);

    peanoCellGeoSize = getPeanoCellGeoSize(spatialExtent, resolution, unit);
    queryMinCoord = getCoordinateOnGrid(query(1:2), minCoord, peanoCellGeoSize, unit);
    queryMaxCoord = getCoordinateOnGrid(query(3:4), minCoord, peanoCellGeoSize, unit);
    minZVal = zValueBase5(resolution, queryMinCoord);
    maxZVal = zValueBase5(resolution, queryMaxCoord);
    minZVal = padString(longestCommonPrefix(minZVal, maxZVal), resolution, '0');

    idsZVal = runWindowQueryWithZValue(query, minZVal, maxZVal, windowQueryWithZValueTable);

    assert(length(ids) == length(idsZVal));
end

