%start with ordered list: 1 2 3 4
%for a given list:
%   find all n>1 which are in their place (list == [1 2 3 4])
%   	for each 1, repeat recursively
%       if all are 0: return number of hops and current list
%dies around n=13

%for 13 (80 shuffles):
%[2 9 4 5 11 12 10 1 8 13 3 6 7]

%for 53, I estimate 1e7, based on an exponential fit to the first 13
%solutions

function [cardList, totalShuffles] = findShuffles(cards)
 [totalShuffles, cardList] = findJumps(cards, 0);
 totalShuffles = totalShuffles(1);
end

function [nHops, list] = findJumps(cards, n)
    inOrder = (cards == [0, 2:length(cards)]);
    if sum(inOrder)==0
        nHops = n;
        list = cards;
        return
    else
        hops = zeros(sum(inOrder)*50, 1);
        lists = zeros(sum(inOrder)*50, length(cards));
        m = 1;
        for i=find(inOrder)
            prevCards = [flip(cards(1:i)), cards(i+1:end)];
            [h, l] = findJumps(prevCards, n+1);
            hops(m:m+length(h)-1) = h;
            lists(m:m+length(h)-1, :) = l;
            m = m+length(h);
        end
        ind = (hops == max(hops));
        nHops = hops(ind);
        list = lists(ind, :);
        return
    end
end