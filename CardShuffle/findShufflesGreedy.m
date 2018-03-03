%start with ordered list: 1 2 3 4
%for a given list:
%   find all n>1 which are in their place (list == [1 2 3 4]
%   	for each 1, perform a shuffle and count the number in place
%       pick whichever had the greatest number of options and follow it
%       all 0: return number of hops and current list

%for 13 (80 shuffles):
%[2 9 4 5 11 12 10 1 8 13 3 6 7]

cards = 1:13;

inOrder = (cards == [0, 2:length(cards)]);
n = 0;
while (sum(inOrder))
    trialCards = zeros(sum(inOrder), length(cards));
    ordered = zeros(size(trialCards));
    m = 1;
    for i=find(inOrder)
        trialCards(m,:) = [flip(cards(1:i)), cards(i+1:end)];
        ordered(m,:) = (trialCards(m,:) == [0, 2:length(cards)]);
        m = m+1;
    end
    [~, best] = max(sum(ordered, 2));
    inOrder = ordered(best, :);
    cards = trialCards(best, :);
    n = n+1;
end

totalShuffles = n
cardList = cards
