accId = 4;
trial = 6;

nCol = 1;
nRow = 1;

figure(21)
clf

detect = detected(accId).trial(trial).filter6;
mag = data(accId).trial(trial).mag;
gyro = data(accId).trial(trial).gyro;
corrData = data(accId).trial(trial).corr(1, :);

ranges = 1:450;

samples = mag.sample(ranges, :);
detects = detect(ranges);

subplot(nRow, nCol, 1)
hold on
plot(samples)
stem(find(detects), samples(detects), 'LineStyle','none')
legend('x', 'y', 'z')
%xticks([])
yticks([])