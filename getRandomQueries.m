function queries = getRandomQueries(n, spatialExtent)
minCoord = spatialExtent(1:2);
maxCoord = spatialExtent(3:4);
queries = zeros(n, 4);
for queryId=1:n
    randCoords = rand(2, 2);
    randMinCoord = min(randCoords);
    randMaxCoord = max(randCoords);
    query = [((maxCoord(1) - minCoord(1)) * randMinCoord(1)) + minCoord(1), ...
             ((maxCoord(2) - minCoord(2)) * randMinCoord(2)) + minCoord(2), ...
             ((maxCoord(1) - minCoord(1)) * randMaxCoord(1)) + minCoord(1), ...
             ((maxCoord(2) - minCoord(2)) * randMaxCoord(2)) + minCoord(2)];
    queries(queryId, :) = query;
end
end

