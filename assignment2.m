%% Bootstrap
% Add data path
addpath('data');

% Start parallel pool
parfor i=1:1
    disp('Successfully started parallel pool.');
end

%% Task 0 [0 marks] Dataset preprocessing
% Load dataset

[D, geometries] = loadDataset('./data/Buildings.xlsx');

% Calculate the spatial extend
n = height(D);
spatialExtent = getSpatialExtent(geometries);

% Calculate the MBRs
mbrs = getMBRs(geometries);

%% Task 1 [12 marks] R-tree implementation.
% (1) [4 marks] Write a program to create an R-tree index for polygon data 
%     in-memory. The fan-out of the tree should be d (i.e., a non-leaf node
%     can have a maximum of d MBRs/subtrees), and each leaf node can 
%     contain a maximum of n polygons (i.e., the bucket size is n), where 
%     both d and n are user-given parameters. You can implement your 
%     program by looking at or using any code online (please make sure that 
%     the code is correct and suitable for this assignment, and that you do 
%     understand the code! The source of the code, if you use the code from 
%     other sources, must be acknowledged in your report).
% See: RTree.m

% (2) [4 marks] Provide a concise outline of the algorithm you implement, 
%     with sufficient plain English comments such that your code can be 
%     easily understood by other people.
% See: report

% (3) [4 marks] Use the program developed above to create an R-tree index 
%     for the polygon dataset D. You create an R-tree for the first half of 
%     D, and then for the entire D, and report for each case the following 
%     statistics with n=64 and 256 and d = 8 and 32 respectively (i.e., a 
%     total of 4 cases for the first half of D and then for the entire D):
%     a. [1 mark] the height of your R-tree index.
%     b. [1 mark] the numbers of non-leaf and leaf nodes.
% Split the dataset by half
mbrsHavlved = mbrs(1:n/2, :);
geometriesHavled = geometries(1:n/2, :);

% Create R-trees
tic
d = 8;
n = 64;
fprintf("d = %d, n = %d\n", d, n);
rtree1Halved = RTree(d, n);
rtree1Halved.build(mbrsHavlved, geometriesHavled, true);
rtree1Halved.summary(true);

rtree1 = RTree(d, n);
rtree1.build(mbrs, geometries, true);
rtree1.summary(true);

d = 8;
n = 256;
fprintf("d = %d, n = %d\n", d, n);
rtree2Halved = RTree(d, n);
rtree2Halved.build(mbrsHavlved, geometriesHavled, true);
rtree2Halved.summary(true);

rtree2 = RTree(d, n);
rtree2.build(mbrs, geometries, true);
rtree2.summary(true);

d = 32;
n = 64;
fprintf("d = %d, n = %d\n", d, n);
rtree3Halved = RTree(d, n);
rtree3Halved.build(mbrsHavlved, geometriesHavled, true);
rtree3Halved.summary(true);

rtree3 = RTree(d, n);
rtree3.build(mbrs, geometries, true);
rtree3.summary(true);

d = 32;
n = 256;
fprintf("d = %d, n = %d\n", d, n);
rtree4Halved = RTree(d, n);
rtree4Halved.build(mbrsHavlved, geometriesHavled, true);
rtree4Halved.summary(true);

rtree4 = RTree(d, n);
rtree4.build(mbrs, geometries, true);
rtree4.summary(true);
toc

%% Task 2 [14 marks] Window query processing. For a query window q which is 
%   a rectangle, find polygons p in D that are within the query window q.
% (1) [3 marks] Write a program that can process the window query by 
%     exhaustive search (i.e., checking all polygons in D to see if they 
%     are inside q).
% See: runWindowQuery.m

% (2) [7 marks] Write a program that can process the window query based on 
%     the R-tree implemented in Task 1 using the algorithm.
% See: RTree.windowQuery

% (3) [4 marks] Generate 30 random query windows of different size and at 
%     different locations, and run the two window query processing programs 
%     you implemented above to report the following statistics (please use 
%     n=256, d = 8 for your R-tree):
%     a. [1 mark] The number of objects in the query window.
%     b. [2 mark] The running time to execute each query for the two 
%        algorithms (you % should run your algorithms multiple times for 
%        each query and report the min/max/avg time).
%     c. [1 mark] The number of polygons in D that have been checked.
rtree = RTree(8, 256);
rtree.build(mbrs, geometries, true);
rtree.summary(true);

queries = getRandomQueries(30, spatialExtent);
experiments = 10;

% Prepare for exhaustive search
windowQueryTable = D(:, {'id'});
windowQueryTable.mbrs = mbrs;

for queryId=1:length(queries)
    query = queries(queryId, :);

    % Experiment results
    expResults = zeros(1, experiments);

    % Print the current query
    fprintf("(%f, %f), (%f, %f) & ", query(1), query(2), query(3), query(4));
    
    % Exhaustive search
    for expCnt=1:experiments
        startTime = tic;
        [exhaustiveSearchRes, qryStat] = runWindowQuery(query, windowQueryTable);
        elapsed = toc(startTime);
        expResults(1, expCnt) = elapsed;
    end

    % Display statistics for exhaustive search
    fprintf("%d & %d & %.2f s &", length(exhaustiveSearchRes), qryStat.compareCount, mean(expResults));
    
    % With R-tree
    for expCnt=1:experiments
        startTime = tic;
        [rTreeSearchRes, qryStat] = rtree.windowQuery(query);
        assert(length(exhaustiveSearchRes) == length(rTreeSearchRes));
        elapsed = toc(startTime);
        expResults(1, expCnt) = elapsed;
    end

    % Display statistics for search with R-tree
    fprintf(" %d & %d & %.2f s \\\\\n", length(rTreeSearchRes), qryStat.compareCount, mean(expResults));
end

%% Tests
% Ensure the correctness of the windows query with R-tree
testQueries = getRandomQueries(10000, spatialExtent);
m = length(testQueries);
parfor queryId=1:m
    fprintf("Current query id: %d\n", queryId);
    query = testQueries(queryId, :);
    exhaustiveSearchRes = runWindowQuery(query, windowQueryTable);
    rTreeSearchRes = rtree.windowQuery(query);
    assert(length(exhaustiveSearchRes) == length(rTreeSearchRes));
end

