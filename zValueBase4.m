function z = zValueBase4(n, pos)
if n <= 4
    z = uint8(0);
elseif n <= 8
    z = uint16(0);
elseif n <= 16
    z = uint32(0);
elseif n <= 32
    z = uint64(0);
else
    error('n is too large.');
end
[minX, minY] = deal(1);
[maxX, maxY] = deal(2^n);
x = pos(1);
y = pos(2);
while 1
    midX = ((maxX - minX + 1) / 2) + minX - 1;
    midY = ((maxY - minY + 1) / 2) + minY - 1;
    if x <= midX && y <= midY
        z = z + 0;
        maxX = midX;
        maxY = midY;
    elseif x <= midX && y > midY
        z = z + 1;
        maxX = midX;
        minY = midY + 1;
    elseif x > midX && y <= midY
        z = z + 2;
        minX = midX + 1;
        maxY = midY;
    else
        z = z + 3;
        minX = midX + 1;
        minY = midY + 1;
    end
    n = n - 1;
    if n <= 0
        break
    end
    z = bitshift(z, 2);
end
end

