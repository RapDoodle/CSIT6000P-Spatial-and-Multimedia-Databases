function geoSize = getPeanoCellGeoSize(spatialExtent, resolution, unit)
spatialExtentGeoSize = getSpatialExtentGeoSize(spatialExtent, unit);
geoSize = spatialExtentGeoSize ./ (2^resolution);
end

