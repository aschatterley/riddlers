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

shapeColor = optimvar('shapeColor', 4, 14, 'Type', 'integer', ...
    'UpperBound', 1, 'LowerBound', 0);

%lock in the two big ones to be the same color
shapeColor(1,3).LowerBound = 1;
shapeColor(2,13).LowerBound = 1;

%some random objective
ostProb.Objective = sum(sum(shapeColor .* rand(size(shapeColor))));

%now for constraints
%1) only one per row
ostProb.Constraints.bool = sum(shapeColor) == 1;

%2) areas add up to 36
areaMat = repmat(areas, 4, 1);
ostProb.Constraints.areas = sum(shapeColor .* areaMat, 2) == 36;

%3) no neighbours sharing a color
ostProb.Constraints.neigh = optimconstr(20, 4);

n = 1;
for col =(1:14)
    for row=(1:col)
        if neighbours(row,col)
            ostProb.Constraints.neigh(n, :) = (shapeColor(:,row) + shapeColor(:,col)) <= 1;
            n = n+1;
        end
    end
end

ostProb.Constraints.banList = optimconstr(100,2);

figure;
for n=1:1000
    
    [ostSol, ~, ~, solInfo] = ostProb.solve();
    ostSol.shapeColor = round(ostSol.shapeColor);
    if solInfo.numfeaspoints < 1
        break
    end
    
    %ban this solution
    ostProb.Constraints.banList(n,1) = sum(shapeColor(logical(ostSol.shapeColor))) <= sum(ostSol.shapeColor(:)) -1;
    
    %also ban the solution with colors 3 & 4 swapped
    ostSol.shapeColor =  ostSol.shapeColor([1 2 4 3], :);
    ostProb.Constraints.banList(n,2) = sum(shapeColor(logical(ostSol.shapeColor))) <= sum(ostSol.shapeColor(:)) -1;

    plotOst(ostSol.shapeColor, shapes, areas, n)
end

plot([0 0 NaN 12 12 NaN 24 24 NaN 36 36 NaN], ...
     [0 36 NaN 0 36 NaN 0 36 NaN 0 36 NaN], 'LineWidth', 3, 'Color', 'k'); 
 
 plot([0 36 NaN 0 36 NaN 0 36 NaN 0 36 NaN], ...
     [0 0 NaN 12 12 NaN 24 24 NaN 36 36 NaN], 'LineWidth', 3, 'Color', 'k'); 

 axis tight
axis square
 
function [] = plotOst(shapeColor, shapes, areas, plotN)

colors = [  1, 0.5 ,0.5;
            0.5, 0.5, 1;
            1, 1, 0.5;
            0.8, 0.8, 0.8];
        
for n=1:length(shapes)
    dx = mod(plotN-1, 3)*12;
    dy = floor((plotN-1)/3)*12;
    
    fill(shapes{n}(:,1)+dx, shapes{n}(:,2)+dy, ...
        colors(find(shapeColor(:, n), 1),:) ); hold on
%    text(mean(shapes{n}(:,1)), mean(shapes{n}(:,2)), num2str((n)));
    text(mean(shapes{n}(:,1))+dx-0.3, mean(shapes{n}(:,2))+dy, num2str(areas(n)));
%    grid on
end

end