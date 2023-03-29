function [ids, stats] = runWindowQuery(query, data)
[n, ~] = size(data);
ids = [];
for i=1:n
    currMbr = data{i, 'mbrs'};
    if all(currMbr(1:2) >= query(1:2)) && all(currMbr(3:4) <= query(3:4))
        ids(end+1) = data{i, 'id'};
    end
end
end

