blanks = zeros(7, 2);

for n=(1:7)
    fprintf('Solving continent %d\n\n', n);
    [map, blanks(n,:)] = solveIsland(sprintf('continent%d.txt', n));
    for m=1:size(map, 1)
        fprintf([map(m, :) '\n']);
    end
    fprintf( '\n\nBlank sign numbers are %d & %d\n\n\n', blanks(n,1), blanks(n,2));
end

fprintf('Solving world\n\n');
[map] = solveIsland(sprintf('world.txt'));
for m=1:size(map, 1)
    fprintf([map(m, :) '\n']);
end
fprintf('\n\n\n');


%the order comes from the world island puzzle
continentOrder = [4 3 6 7 5 2 1];

fprintf('*****\n');
for n=(1:7)
    fprintf(char('A' + blanks(continentOrder(n),:) - 1));
end
fprintf('\n*****\n');
