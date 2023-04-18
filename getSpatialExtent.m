function spatialExtent = getSpatialExtent(geometries)
n = length(geometries);
minCoord = ones(1, 2) * double(intmax("int32"));
maxCoord = ones(1, 2) * double(intmin("int32"));
for i=1:n
    minCoord = min([geometries{i}; minCoord]);
    maxCoord = max([geometries{i}; maxCoord]);
end
spatialExtent = [minCoord, maxCoord];
end

