function [] = evaluateCards(cards)
%evaluateCards Print the route taken from a given starting deck

while(cards(1) ~= 1)
    disp(cards);
    cards(1:cards(1)) = flip(cards(1:cards(1)));
end
disp(cards);

