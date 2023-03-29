function geoSize = getSpatialExtentGeoSize(spatialExtent, unit)
geoSize = getGeoSize(spatialExtent(1:2), spatialExtent(3:4), unit);
end

