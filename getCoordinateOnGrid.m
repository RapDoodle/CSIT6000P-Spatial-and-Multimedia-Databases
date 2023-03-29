function coordinate = getCoordinateOnGrid(position, origin, peanoCellSize, unit)
if nargin < 4
    unit = 'cm';
end
% Real distance to the minCoor
geoSize = getGeoSize(origin, position, unit);

% Calculate the position on the grid
coordinate = max(ceil(geoSize ./ peanoCellSize), 1);
end

