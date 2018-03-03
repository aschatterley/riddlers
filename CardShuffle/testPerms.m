maxN = 10;

best = 0;

for p = perms(2:maxN)'
    [cardList, totalShuffles] = findShuffles([1 p']);
    if totalShuffles > best
        disp(p');
        disp(best);
        best = totalShuffles;
    end
end