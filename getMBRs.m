function mbrs = getMBRs(geometries)
n = length(geometries);
mbrs = zeros(n, 4);
parfor i=1:n
    currMinCord = min(geometries{i});
    currMaxCord = max(geometries{i});
    mbrs(i, :) = [currMinCord(1), currMinCord(2), ...
                  currMaxCord(1), currMaxCord(2)];
end
end

