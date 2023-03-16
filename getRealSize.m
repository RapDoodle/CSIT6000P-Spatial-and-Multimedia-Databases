function [w, h] = getRealSize(coordinate1, coordinate2, metric)
wgs84 = wgs84Ellipsoid(metric);
w = distance(coordinate1(2), coordinate1(1), coordinate1(2), coordinate2(1), wgs84);
h = distance(coordinate1(2), coordinate1(1), coordinate2(2), coordinate1(1), wgs84);
end

