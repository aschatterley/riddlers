blanks = zeros(7, 2);

for n=(1:7)
    fprintf('Solving continent %d\n\n', n);
    [map, blanks(n,:)] = solveIsland(sprintf('continent%d.txt', n));
    for m=1:size(map, 1)
        fprintf([map(m, :) '\n']);
    end
    fprintf( '\n\nBlank sign numbers are %d & %d = %s%s\n-----\n\n', ...
        blanks(n,1), blanks(n,2), blanks(n,1)+'A'-1, blanks(n,2)+'A'-1);
end

fprintf('Solving world\n\n');
[map] = solveIsland(sprintf('world.txt'));
for m=1:size(map, 1)
    fprintf([map(m, :) '\n']);
end
fprintf('\n\n\n');

%get the order from the world puzzle
%the extra islands on the edges are to simulat the wrapping around
wrapMap = map(:, 2:end-1)';

continentOrder = wrapMap(wrapMap>'0' & wrapMap<'9')';
fprintf('Continent order = %s\n\n', continentOrder);


fprintf('Converting blanks to letters and sorting by continent order:\n*****\n');
for n=(1:7)
    fprintf(char('A' + blanks(continentOrder(n)-'0',:) - 1));
end
fprintf('\n*****\n');
