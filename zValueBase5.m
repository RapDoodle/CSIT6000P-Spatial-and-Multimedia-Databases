function z = zValueBase5(n, pos)
m = n;
z = zeros(1, n);
[minX, minY] = deal(1);
[maxX, maxY] = deal(2^n);
x = pos(1);
y = pos(2);
while n > 0
    midX = ((maxX - minX + 1) / 2) + minX - 1;
    midY = ((maxY - minY + 1) / 2) + minY - 1;
    if x <= midX && y <= midY
        curr = '1';
        maxX = midX;
        maxY = midY;
    elseif x <= midX && y > midY
        curr = '2';
        maxX = midX;
        minY = midY + 1;
    elseif x > midX && y <= midY
        curr = '3';
        minX = midX + 1;
        maxY = midY;
    else
        curr = '4';
        minX = midX + 1;
        minY = midY + 1;
    end
    z(m - n + 1) = curr;
    n = n - 1;

end
z = char(z);
end

