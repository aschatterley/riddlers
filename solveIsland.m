%
% This function uses integer linear programming to solve the islands puzzle
% We solve for how many bridges there should be between each linkable set
% of islands, subject to the constraints given by the diamond shaped signs
%
% Note that this requires matlab2017b with the optimaztion toolbox to
% function
%
%we need :
% variables:
%     bridge1 for each bridge [0 1]; is there a bridge between isles n&m?
%     bridge2 for each bridge [0 1]; is it a double bridge?
%     booleans for inequalities; we need this to elimate equal pairs in each group
%     
% constraints:
%     island scores as determined by diamond signs
%     no equal islands (using bool variable above too)
%     no crossover for each valid cross point: bridge1H + bridge1V <= 1
%         
% so this requires:
%     list of valid bridges
%     list of bridges associated with each diamond sign
%     list of island-island pairs within each diamond group
%     list of possible crossovers, and which bridges could interfere

% note that the spec also said that every island has to be connected. I
% all solutions I got had this anyway, so there's no extra constraint for
% this
%
% the reason for the two bridge variables is to make the no crossover
% constraint easier to implement
%
% interestingly, you get the exact same numbers for the blank signs (and
% thus puzzle solution) even if the no cross constraint is relaxed


function [map, blanks] = solveIsland(filename)

[cont, signs] = readContinent(filename); %read in the island map
[bridgeList, bridges] = makeBridgeList(cont); %make a bridgeage matrix
[islandGroups, groupSum] = findGroups(cont, signs); %assign islands to groups
[groupPairs] = findGroupPairs(islandGroups); %get the pairs within each group
[crossover] = findCrossovers(cont, bridgeList); %find places where two bridges could cross

nGroups = length(islandGroups);
nBridges = size(bridgeList, 1);
nPairs = size(groupPairs, 1);
nCrossover = size(crossover, 1);
nIslands = sum(cont(:) > 0);
%now we're ready to get optimizing!
bridgeProb = optimproblem;

%first come the variables

%these decide whether or not to build each bridge
%there's two of them, because you can build two bridges between each
%island, and it makes detecting crossovers easier if bridge1 is a descision
%variable showing whether or not there's a bridge
bridge1 = optimvar('bridge1', nBridges, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
bridge2 = optimvar('bridge2', nBridges, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);

%we need this variable to decide which is larger for each group pair
%this lets us make an inequality contraint
eqBool = optimvar('eqBool', nPairs, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);

rng(1); %add a random objective to break symmetry
bridgeProb.Objective = sum(bridge1.*rand(size(bridge1))) + sum(bridge2.*rand(size(bridge2)));

%the score for each island
[islandScores] = getIslandScores(bridgeList, bridge1, bridge2, nIslands);

%constraints:
%1) bridge2 <= bridge1; so bridge1 is the decision maker
bridgeProb.Constraints.bridgeNum = bridge2 <= bridge1;

%2) sum of each group as indicated by signs
bridgeProb.Constraints.groupSumEq = optimconstr(nGroups);
for n=1:nGroups
    groupExp = optimexpr();
    
    %for each island in group, add up all affecting bridges
    for m=1:length(islandGroups{n})
        groupExp = groupExp + islandScores(islandGroups{n}(m));
    end
    
    if groupSum(n) ~= 99 %99 means it was a ? in the problem
        bridgeProb.Constraints.groupSumEq(n) = sum(groupExp) == groupSum(n);
    end
end

%3) no crossovers
bridgeProb.Constraints.crossCons = optimconstr(size(crossover, 1));
for n=1:nCrossover
    bridgeProb.Constraints.crossCons(n) = sum(bridge1(crossover(n, :))) <= 1;
end


%4) no equal scores in a group
bridgeProb.Constraints.noPairs1 = optimconstr(size(nPairs, 1));
bridgeProb.Constraints.noPairs2 = optimconstr(size(nPairs, 1));
M = 1000; %so that we can do an inequality, but keep it linear
for n=1:nPairs
    %effectively, this gives score1 ~= score2
    bridgeProb.Constraints.noPairs1(n) =  islandScores(groupPairs(n,1)) - islandScores(groupPairs(n,2)) + M*eqBool(n) >= 1;
    bridgeProb.Constraints.noPairs2(n) =  islandScores(groupPairs(n,1)) - islandScores(groupPairs(n,2)) + M*eqBool(n) <= M-1;
end

%and throw it into the solver
opts = optimoptions('intlinprog', 'Display', 'none');
bridgeSol = solve(bridgeProb, opts);
bridgeSol.bridge1 = round(bridgeSol.bridge1); %clean up the integers
bridgeSol.bridge2 = round(bridgeSol.bridge2);

solvedScores = getIslandScores(bridgeList, bridgeSol.bridge1, bridgeSol.bridge2, nIslands);

%and get the solved map
map = outputContinent(cont, bridgeSol, bridgeList, solvedScores);

%finally, we should find the missing sign values
n = 1;
blanks = [0 0];
for blankSign = find(groupSum == 99)'
    groupTotal = 0;
    %for each island in group, add up all affecting bridges
    for m=1:length(islandGroups{blankSign})
        island = islandGroups{blankSign}(m);
        %make a logical list of affected bridges
        bridgesInGroup = bridgeList(:,1)==island | bridgeList(:,2)==island;
        groupTotal = groupTotal + sum(bridgeSol.bridge1(bridgesInGroup) + bridgeSol.bridge2(bridgesInGroup));
    end
    blanks(n) = round(groupTotal);
    n = n+1;
end
end

%draw the solution
function [bigMap] = outputContinent(cont, bridgeSol, bridgeList, scores)
%if we flip it first, this becomes a lot easier
cont = cont';

map = char(zeros(size(cont)));
map(cont<0) = 'x'; %fill in the signs
%map(cont>0) = 'o';

%replace each island with its score

map(cont>0) = char('0' + scores);
map = map';
cont = cont';

bigMap = char(zeros(size(cont)*2-1));
bigMap(1:2:end, 1:2:end) = map;

for n=1:size(bridgeList, 1)
    if bridgeSol.bridge1(n)
        if bridgeList(n, 2) - bridgeList(n, 1) == 1 %if they're adjacent, it's horiz
            [row(1), col(1)] = find(cont == bridgeList(n, 1), 1);
            [row(2), col(2)] = find(cont == bridgeList(n, 2), 1);
            if bridgeSol.bridge2(n)
                bigMap(row(1)*2-1, col(1)*2:col(2)*2-2) = '=';
            else
                bigMap(row(1)*2-1, col(1)*2:col(2)*2-2) = '-';
            end
        else %they must be vert
            [row(1), col(1)] = find(cont == bridgeList(n, 1), 1);
            [row(2), col(2)] = find(cont == bridgeList(n, 2), 1);
            if bridgeSol.bridge2(n)
                bigMap(row(1)*2:row(2)*2-2, col(1)*2-1) = '#';%for some reason, ? doesn't work when run as a script?
            else
                bigMap(row(1)*2:row(2)*2-2, col(1)*2-1) = '|';
            end
        end
    end
end
end

%get the score for each island, i.e. how many bridges touch it?
function [islandScores] = getIslandScores(bridgeList, bridge1, bridge2, nIslands)
if isa(bridge1, 'double') %this way it can be either a double or optimexpr
    islandScores = zeros(nIslands, 1);
else
    islandScores = optimexpr(nIslands);
end
for n=1:nIslands
    bridgesInGroup = bridgeList(:,1)==n | bridgeList(:,2)==n;
    islandScores(n) = sum(bridge1(bridgesInGroup) + bridge2(bridgesInGroup));
end
end

%this function finds every potnetial spot where a - and | path could cross
function [crossover] = findCrossovers(cont, bridgeList)
crossover = zeros(length(bridgeList), 2); %we'll trim it later
%(i just hate the matlab changing variable size warning)
n=1;
for row=1:size(cont, 1)
    for col=1:size(cont, 2)
        if ~cont(row, col)
            try %in case we hit a boundry
                [~, ~, N] = find(cont(1:row-1, col), 1, 'last');
                [~, ~, E] = find(cont(row, col+1:end), 1, 'first');
                [~, ~, S] = find(cont(row+1:end, col), 1, 'first');
                [~, ~, W] = find(cont(row, 1:col-1), 1, 'last');
                
                %there's a crossover potential if a 0 is surrounded by +ves
                if N>0 && E>0 && S>0 && W>0
                    %this finds where these particular bridges are in the
                    %list
                    crossover(n, 1) = find(bridgeList(:,1)==N & bridgeList(:,2)==S);
                    crossover(n, 2) = find(bridgeList(:,1)==W & bridgeList(:,2)==E);
                    n = n+1;
                end
                
            catch
            end
        end
    end
end
crossover = crossover(1:find(crossover(:,1)==0, 1)-1, :);
end

%find every pair with each group. We need this to satisfy the inequality
%constraint within each group
function [groupPairs] =  findGroupPairs(islandGroups)
groupPairs = cell(length(islandGroups), 1);
for n=1:length(groupPairs)
    if length(islandGroups{n}) > 1
        groupPairs{n} =  nchoosek(islandGroups{n}, 2);
    else
        groupPairs{n} = [];
    end
end
groupPairs = cell2mat(groupPairs); %make it a matrix for easier handling
end

%find groups pointed to by signs and get their sums from the signs
function [islandGroups, groupSum] = findGroups(cont, signs)
n = 1;
groupSum = zeros(sum(sum(signs>0)), 1);
islandGroups = cell(sum(sum(signs>0)), 1);

%run through each sign
for signN=1:size(signs, 1)
    [row, col] = find(cont==-signN, 1); %find the next sign and take the 4 groups around it
    if isempty(row)
        break
    end
    %order is N E S W
    if signs(signN, 1) %N
        [~, ~, islandGroups{n}] = find(cont(1:row-1, col));
        groupSum(n) = signs(signN, 1);
        n = n+1;
    end
    if signs(signN, 2) %E
        [~, ~, islandGroups{n}] = find(cont(row, col+1:end));
        groupSum(n) = signs(signN, 2);
        n = n+1;
    end
    if signs(signN, 3) %S
        [~, ~, islandGroups{n}] = find(cont(row+1:end, col));
        groupSum(n) = signs(signN, 3);
        n = n+1;
    end
    if signs(signN, 4) %W
        [~, ~, islandGroups{n}] = find(cont(row, 1:col-1));
        groupSum(n) = signs(signN, 4);
        n = n+1;
    end
end
end

%find all allowable bridges
function [bridgeList, bridges] = makeBridgeList(cont)
nIslands = max(cont(:));

bridges = zeros(nIslands); %lets just make a bridgeage matrix to start with

%let's just do this for each island
for n=1:nIslands
    [row, col] = find(cont==n); %find the relevant row
    try
        [~, ~, nextInRow] = find(cont(row, col+1:end), 1);
        if nextInRow>0
            bridges(n, nextInRow) = 1;
        end
    catch
    end
    
    try %in case we spill over the edge
        [~, ~, nextInCol] = find(cont(row+1:end, col), 1);
        if nextInCol>0
            bridges(n, nextInCol) = 1;
        end
    catch
    end
end
%turn it into a list of island-island links available
[bridgeList(:,1), bridgeList(:,2)] = find(bridges);
end

%read in the file describing the continent
% the format is:
% m x n matrix describing the map
% symbols are: - for space, o for island, x for sign
% 
% comma separated values on the signs, reading from top down
% each line is the four values, going clockwise from the top
% a value of 0 means there is nothing to this side of the sign
% a value of 99 means the value is unknown
function [cont, signs] = readContinent(name)
d = importdata(name);
contSize = [length(d.textdata), length(d.textdata{1})];

signs = d.data; %the signs come out in this mat
cont = zeros(contSize); %the rest comes out as text
signN = 1;
islandN = 1;
for n=1:contSize(1)
    for m=1:contSize(2)
        switch d.textdata{n}(m)
            case '-'
                cont(n,m) = 0;
            case 'o'
                cont(n,m) = islandN;
                islandN = islandN + 1;
            case 'x'
                cont(n,m) = -signN;
                signN = signN + 1;
            otherwise
                error(['unkown symbol ', d.textdata{n}(m)]);
        end
    end
end

end
