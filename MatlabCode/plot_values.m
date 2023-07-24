figure(8)
clf

accId = 8;
showTrials = 1:5;

nCol = length(showTrials);
nRow = 3;
disp(data(accId).name)

for cnt = 1:length(showTrials)
    detect = detected(accId).trial(showTrials(cnt)).filter6;
    mag = data(accId).trial(showTrials(cnt)).mag;
    gyro = data(accId).trial(showTrials(cnt)).gyro;

    subplot(nRow, nCol, cnt)
    hold on
    plot(mag.diff)
    title('diff')
    legend({'x', 'y', 'z'})

    subplot(nRow, nCol, nCol + cnt)
    plot(mag.sample)
    title('mag values')

    subplot(nRow, nCol, nCol*2 + cnt)
    plot(mag.inferAngle)
end