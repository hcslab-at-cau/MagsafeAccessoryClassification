accId = 4;
showTrials =4:6;
threshold = 50;

figure(9)
clf

nCol = length(showTrials);
nRow = 2;
disp(data(accId).name)

for cnt = 1:length(showTrials)
    detect = detected(accId).trial(showTrials(cnt)).filter6;
    mag = data(accId).trial(showTrials(cnt)).mag;
    gyro = data(accId).trial(showTrials(cnt)).gyro;
    corrData = data(accId).trial(showTrials(cnt)).corr(1, :);
    diff = mag.diff;
    diffMagnitude = zeros(1, length(diff(1, :)));

    for cnt2 = 1:length(diffMagnitude)
        diffMagnitude = sqrt(sum(diff.^2, 2));
    end

    diffFilter = diffMagnitude > threshold;

    subplot(nRow, nCol, cnt)
    plot(diffMagnitude)

    subplot(nRow, nCol, nCol + cnt)
    plot(diffFilter)
    
end