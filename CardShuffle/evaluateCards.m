function [] = evaluateCards(cards)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
while(cards(1) ~= 1)
disp(cards);
cards(1:cards(1)) = flip(cards(1:cards(1)));
end
disp(cards);

