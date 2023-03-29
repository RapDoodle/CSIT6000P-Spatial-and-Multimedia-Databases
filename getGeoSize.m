function geoSize = getGeoSize(coordinate1, coordinate2, unit)
wgs84 = wgs84Ellipsoid(unit);
w = distance(coordinate1(2), coordinate1(1), coordinate1(2), coordinate2(1), wgs84);
h = distance(coordinate1(2), coordinate1(1), coordinate2(2), coordinate1(1), wgs84);
geoSize = [w, h];
end

