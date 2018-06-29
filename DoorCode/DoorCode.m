n = 4; %digits in door code
kMax = 10; %number of digits on keypad

fid = fopen('digits.txt', 'w');
%fid = 1;

pushed = (repmat('0', 1, n));
fprintf(fid, [pushed]);

keyPresses = n;

for k = 2:kMax
possibleCodes = string(dec2base(0:k^n-1, k)); %all possible codes
%but we only want the ones containing a k
kCodes = string(possibleCodes(contains(possibleCodes, dec2base(k-1, k)), :));

%we need to reserve codes like '222', '220' and '200'
for j=0:n-1
    kCodes(strcmp(kCodes, string([repmat(dec2base(k-1, k), 1, n-j) repmat('0', 1, j)]))) = [];
end

%numCodes = base2dec(kCodes, k); %life is easier if numbers are numbers


%keep going till we run out
availableCodes = ones(length(kCodes), 1);
while sum(availableCodes)
    nextCode = find(startsWith(kCodes, pushed(end-n+2:end)) & availableCodes, 1);
    key = extractAfter(kCodes(nextCode), strlength(kCodes(nextCode))-1);
    assert(strlength(key) == 1, 'key wrong length');
    pushed = [pushed(2:end) char(key)];
    availableCodes(nextCode) = 0;
    fprintf(fid, key);
    keyPresses = keyPresses + 1;
end

%now for the exluded ones. Pushed will end with (n-1) of current num
%se we only need to add one more, then start padding with 0s
fprintf(fid, dec2base(k-1, k));
fprintf(fid, repmat('0', 1, n-1));
pushed = [dec2base(k-1, k) (repmat('0', 1, n-1))];
keyPresses = keyPresses + n;
fprintf(fid, '\n');
end

fprintf('key presses = %d\n', keyPresses);

if fid ~= 1
fclose(fid);
end

