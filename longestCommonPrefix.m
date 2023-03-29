function commonPrefix = longestCommonPrefix(varargin)
[~, n] = size(varargin);
if n == 0
    commonPrefix = "";
    return
elseif n == 1
    commonPrefix = string(varargin{1});
    return
end

% Convert all to char array
for i=1:n
    if isa(varargin{i}, 'string')
        varargin{i} = varargin{i}.char();
    end
end

% Find the longest common prefix
i = 1;
while 1
    for j=1:n
        if i > length(varargin{j}) || varargin{j}(i) ~= varargin{1}(i)
            commonPrefix = string(varargin{1}(1:i-1));
            return
        end
    end
    i = i + 1;
end
end

