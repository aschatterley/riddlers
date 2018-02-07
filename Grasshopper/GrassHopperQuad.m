%some definitions
lawnArea = 1;
jumpSize = 0.3;

gridSize = 4; %length of bounding box (m)
gridPoints = 100; %number of points to sample on each axis
gridUnit = gridSize/gridPoints;

%jumpMat = zeros(gridPoints^2); %let's try dense for now
%jumpMat = spalloc(gridPoints^2, gridPoints^2, 2*pi*jumpSize/gridUnit);

%make some grids
grids = linspace(0, gridSize, gridPoints);
[x, y] = meshgrid(grids, grids);


%todo: make this use smarter sparse stuff
n = 1;

coord = zeros(2, ceil(2*pi*jumpSize/gridUnit));
m = 1;
for col=1:gridPoints
    for row=1:gridPoints
        j = find(((x-(col-0.5)*gridUnit).^2 + (y-(row-0.5)*gridUnit).^2 > (jumpSize-0*gridUnit/2).^2) & ...
                 ((x-(col-0.5)*gridUnit).^2 + (y-(row-0.5)*gridUnit).^2 < (jumpSize+2*gridUnit/2).^2));
        l = length(j);
        %jumpMat(n,:) = j(:);
        coord(1, m:m+l-1) = n;
        coord(2, m:m+l-1) = j;
        n = n+1;
        m = m+l;
    end
end
jumpMat = sparse(coord(1,:), coord(2,:), ones(size(coord, 2),1), ...
    gridPoints^2, gridPoints^2);

%it's linear for easier matrix mults later
lawn = zeros(1, gridPoints^2);

scores = [];

figure;
p = imagesc(grids, grids, reshape(lawn, gridPoints, gridPoints));
axis image;
n = 1;

offInd = (gridPoints^2+gridPoints)/2;
prior = ones(size(lawn));



while 1%scores(end) ~= scores(end-2)%n <= lawnArea/(gridUnit^2)
    
    %add or remove lawn points
    if  sum(lawn) <= lawnArea/(gridUnit^2)
        lawn(offInd) = 1;
    else
        lawn(onInd) = 0;
    end

    scores(n) = sum(lawn);
    
    %find the scores of each point on the lawn
    lawnScore = lawn * jumpMat;
 
    %find best and worst scores (on and off lawn)
    worstScore = min(lawnScore(lawn==1));
    bestScore  = max(lawnScore(lawn==0));
    
    %find locations of these points
    onInd  = find((lawnScore==worstScore) & (lawn==1));
    offInd = find((lawnScore==bestScore ) & (lawn==0));
    
  
 n = n+1;

 %the world's dumbest steady state detector
if length(scores)>300
    if abs(mean(scores(end-150:end)) - mean(scores(end-300:end-150))) < 0.0025
        break
    end
end


if mod(n, 2)==1
    p.CData = reshape(lawn.*lawnScore, gridPoints, gridPoints) - ...
        reshape(lawnScore.*(1-lawn), gridPoints, gridPoints);

    drawnow;
   % sum(lawn)
end
end