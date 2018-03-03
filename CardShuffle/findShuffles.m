%start with ordered list: 1 2 3 4
%for a given list:
%   find all n>1 which are in their place (list == [1 2 3 4]
%   	each 1, repeat recursively
%       all 0: return number of hops and current list

%for 13 (80 shuffles):
%[2 9 4 5 11 12 10 1 8 13 3 6 7]

% best = 1;
% for p=perms(2:10)'
%     [totalShuffles, cardList] = findJumps([1 p'], 0);
%     if totalShuffles > best
%         fprintf('best n = %d\n', totalShuffles);
%         disp(cardList);
%         best = totalShuffles;
%     end
% end
    
% 
function [totalShuffles, cardList] = findShuffles(nCards)
cards = 1:nCards;
 [totalShuffles, cardList] = findJumps(cards, 0);
end

function [nHops, list] = findJumps(cards, n)
    inOrder = (cards == [0, 2:length(cards)]);
    if sum(inOrder)==0
        nHops = n;
        list = cards;
        return
    else
        hops = zeros(sum(inOrder), 1);
        lists = zeros(sum(inOrder), length(cards));
        m = 1;
        for i=find(inOrder)
            prevCards = [flip(cards(1:i)), cards(i+1:end)];
            [hops(m), lists(m,:)] = findJumps(prevCards, n+1);
            m = m+1;
        end
        [nHops, ind] = max(hops);
        list = lists(ind, :);
        return
    end
end