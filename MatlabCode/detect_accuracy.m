accuracy = zeros(length(data), 2);
acc = strings(1, length(data));

for cnt = 1:length(data)
    accuracy(cnt, 1) = data(cnt).attachAccurracy;
    accuracy(cnt, 2) = data(cnt).detachAccurracy;
    
    acc(cnt) = data(cnt).name;
end

figure(20)
clf
subplot(1, 2, 1)
bar(accuracy(:, 1))
ylim([0, 100])
grid on;
xticklabels(acc);
title('attach accuracy')

subplot(1, 2, 2)
bar(accuracy(:, 2))
ylim([0, 100])
grid on;
xticklabels(acc);
title('detach accuracy')