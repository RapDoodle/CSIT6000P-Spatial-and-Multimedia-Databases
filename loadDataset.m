function [data, geometries] = loadDataset(filename)
data = readtable('Buildings.xlsx');
data = renamevars(data, 'Var1', 'id');

n = height(data);
geometries = cell(n, 1);
regPat = regexpPattern('[^POLYGON \(\(](.)*[^\)\)]');
for i=1:n
    % Extract everything between POLYGON ((...))
    coordinatesStrs = split(extract(data.geometry{i}, regPat), ',');
    % The length of the coordinates for the given building
    m = length(coordinatesStrs);
    coordinates = zeros(m, 2);
    for j=1:m
        coordinate = split(strtrim(coordinatesStrs{j}), ' ');
        coordinates(j, 1) = str2double(coordinate{1});
        coordinates(j, 2) = str2double(coordinate{2});
    end
    geometries{i} = coordinates;
end
end

