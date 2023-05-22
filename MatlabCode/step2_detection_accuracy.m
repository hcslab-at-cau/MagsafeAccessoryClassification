% Simple detection using diff
% diff is difference with Real magentometer and 
% infered magnetometer using gyroscope. 
% It can be use to environment where has no ferromagnetic.

% 1 for attach, 2 for detach
truePositive = zeros(2, length(data)+1);
falsePositive = zeros(1, length(data)+1);
acc = strings(1, length(data)+1);

for cnt = 1:length(data)
    truePositive(1, cnt) = detectList(cnt).tpCount(1)/50 * 100;
    truePositive(2, cnt) = detectList(cnt).tpCount(2)/50 * 100;

    falsePositive(cnt) = detectList(cnt).fpCount;
    acc(cnt) = data(cnt).name;
end

truePositive(1, end) = mean(truePositive(1, 1:length(data)));
truePositive(2, end) = mean(truePositive(2, 1:length(data)));
falsePositive(1, end) = mean(falsePositive(1, 1:length(data)));
acc(end) = "Total Mean";

figure(5)
clf

nRows = 1;
nCols = 3;

subplot(nRows, nCols, 1);
bar(truePositive(1, :))
ylim([0, 100])
grid on;
xticklabels(acc);
title('attach accuracy')

subplot(nRows, nCols, 2);
bar(truePositive(2, :))
ylim([0, 100])
grid on;
xticklabels(acc);
title('detach accuracy')

subplot(nRows, nCols, 3);
bar(falsePositive)
ylim([0, 10])
grid on;
xticklabels(acc);
title('False postive')