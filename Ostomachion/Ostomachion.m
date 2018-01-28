numColors = 3;

%define the ostothing
%just gonna hand code these
shapes = { ...
    [0,0; 2,4; 3,0];
    [2,4; 3,6; 3,0];
    [3,0; 3,6; 4,8; 6,6; 6,0];
    [6,0; 6,6; 8,4];
    [6,0; 8,4; 12,0];
    [8,4; 9,6; 12,0];
    [12,0; 9,6; 12,6];
    [0,0; 2,10; 4,8];
    [0,0; 0,12; 2,10];
    [0,12; 6,12; 4,8];
    [4,8; 6,12; 6,6];
    [6,6; 6,12; 9,6; 8,4];
    [6,12; 12,12; 12,8; 9,6];
    [9,6; 12,8; 12,6]
    };

areas = zeros(1,14);

neighbours = [
       0 1 0 0 0 0 0 1 0 0 0 0 0 0;
       1 0 1 0 0 0 0 1 0 0 0 0 0 0;
       0 1 0 1 0 0 0 1 0 0 1 0 0 0;
       0 0 1 0 1 0 0 0 0 0 0 1 0 0;
       0 0 0 1 0 1 0 0 0 0 0 0 0 0;
       0 0 0 0 1 0 1 0 0 0 0 1 0 0;
       0 0 0 0 0 1 0 0 0 0 0 0 0 1;
       1 1 1 0 0 0 0 0 1 1 0 0 0 0;
       0 0 0 0 0 0 0 1 0 1 0 0 0 0;
       0 0 0 0 0 0 0 1 1 0 1 0 0 0;
       0 0 1 0 0 0 0 0 0 1 0 1 0 0;
       0 0 0 1 0 1 0 0 0 0 1 0 1 0;
       0 0 0 0 0 0 0 0 0 0 0 1 0 1;
       0 0 0 0 0 0 1 0 0 0 0 0 1 0];
   
%work out areas
for n=1:length(shapes)
    areas(n) = polyarea(shapes{n}(:,1), shapes{n}(:,2)); %calculate areas
end

%now for some linear programming

% variables are:
% 12x4 boolean to decide which color each shape gets
%objective is area of each color is the same (36 units)

ostProb = optimproblem();

shapeColor = optimvar('shapeColor', numColors, 14, 'Type', 'integer', ...
    'UpperBound', 1, 'LowerBound', 0);

%lock in the two big ones to be colors 1&2
shapeColor(1,3).LowerBound = 1;
shapeColor(2,13).LowerBound = 1;

%make the remainders more consistent
if numColors == 6
    shapeColor(3,1).LowerBound = 1;
elseif numColors == 4
    shapeColor(4,5).UpperBound = 0;
end

%some random objective
ostProb.Objective = 0;%sum(sum(shapeColor .* rand(size(shapeColor))));

%now for constraints
%1) only one per row
ostProb.Constraints.bool = sum(shapeColor) == 1;

%2) areas add up to the same
areaMat = repmat(areas, numColors, 1);
ostProb.Constraints.areas = optimconstr(numColors-1);
for n=1:numColors-1
    ostProb.Constraints.areas(n) = sum(shapeColor(n,:) .* areas, 2) == sum(shapeColor(n+1,:) .* areas, 2);
end

%3) no neighbours sharing a color
ostProb.Constraints.neigh = optimconstr(20, numColors);
n = 1;
for col =(1:14)
    for row=(1:col)
        if neighbours(row,col)
            ostProb.Constraints.neigh(n, :) = (shapeColor(:,row) + shapeColor(:,col)) <= 1;
            n = n+1;
        end
    end
end


ostProb.Constraints.banList = optimconstr(100,6);

figure;
switch numColors
    case 3
        gridSize = 2;
    case 4
        gridSize = 3;
    case 6
        gridSize = 6;
end

for n=1:(gridSize+1)^2
    
    [ostSol, ~, ~, solInfo] = ostProb.solve();
    ostSol.shapeColor = round(ostSol.shapeColor);
    if solInfo.numfeaspoints < 1
        break
    end
        
    %also ban the solution with remaing color perms swapped
    m = 1;
    for p = perms(3:numColors)'
        shapeColorPerm =  ostSol.shapeColor([1 2 p'], :);
        ostProb.Constraints.banList(n,m) = sum(shapeColor(logical(shapeColorPerm))) <= sum(ostSol.shapeColor(:)) -1;
        m=m+1;
    end
    plotOst(ostSol.shapeColor, shapes, areas, n, gridSize)
    n
    drawnow;
end

for n=0:gridSize
    plot([n n]*12, [0 gridSize]*12, 'LineWidth', 2, 'Color', 'k');
    plot([0 gridSize]*12, [n n]*12, 'LineWidth', 2, 'Color', 'k');
end

 axis tight
axis square
a = gca;
a.Position = [0 0 1 1];
a.XAxis.Visible = 'off';
a.YAxis.Visible = 'off';
f = gcf;
f.Position(4) = f.Position(3);

function [] = plotOst(shapeColor, shapes, areas, plotN, plotSize)

colors = [  1, 0.5 ,0.5;
            0.5, 0.5, 1;
            1, 1, 0.5;
            0.8, 0.8, 0.8;
            0.8, 0.6, 0.2;
            0.2, 0.8, 0.8];
        
for n=1:length(shapes)
    dx = mod(plotN-1, plotSize)*12;
    dy = floor((plotN-1)/plotSize)*12;
    
    fill(shapes{n}(:,1)+dx, shapes{n}(:,2)+dy, ...
        colors(find(shapeColor(:, n), 1),:) ); hold on
  %  text(mean(shapes{n}(:,1)), mean(shapes{n}(:,2)), num2str((n)));
  %  text(mean(shapes{n}(:,1))+dx-0.3, mean(shapes{n}(:,2))+dy, num2str(areas(n)));
%    grid on
end

end