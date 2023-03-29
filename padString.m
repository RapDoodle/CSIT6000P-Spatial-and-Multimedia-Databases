function str = padString(str, len, padChar, outType)
if nargin < 4
    outType = class(str);
end
if isa(str, 'string')
    str = str.char();
end
n = length(str);
for i=n+1:len
    str(i) = padChar;
end
end

