function [ids, stats] = runWindowQueryWithZValue(query, data, spatialExtent, resolution, unit)

peanoCellGeoSize = getPeanoCellGeoSize(spatialExtent, resolution, unit);
queryMinCoord = getCoordinateOnGrid(query(1:2), spatialExtent(1:2), peanoCellGeoSize, unit);
queryMaxCoord = getCoordinateOnGrid(query(3:4), spatialExtent(1:2), peanoCellGeoSize, unit);
minZVal = zValueBase5(resolution, queryMinCoord);
maxZVal = zValueBase5(resolution, queryMaxCoord);
minZVal = padString(longestCommonPrefix(minZVal, maxZVal), resolution, '0');

minZVal = string(minZVal);
maxZVal = string(maxZVal);
zVals = string(data{:, 'zVals'});
[n, ~] = size(data);
% Binary search to look for the first position >= minZVal
lo = int64(1);
hi = int64(n);
startIdx = -1;
while lo <= hi
    mid = (lo + hi) / 2;
    if zVals{mid} >= minZVal
        startIdx = mid;
        hi = mid - 1;
    else
        lo = mid + 1;
    end
end
compareCount = 0;
ids = [];
if startIdx ~= -1
    for i=lo:n
        if zVals{i} > maxZVal
            break;
        end
        currMbr = data{i, 'mbrs'};
        if all(currMbr(1:2) >= query(1:2)) && all(currMbr(3:4) <= query(3:4))
            ids(end+1) = data{i, 'id'};
        end
        compareCount = compareCount + 1;
    end
end
stats.compareCount = compareCount;
end

