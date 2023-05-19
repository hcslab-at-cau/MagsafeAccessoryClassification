accId = 2;
showTrials = 1:2;

figure(10)
clf

nCol = length(showTrials);
nRow = 5;

for cnt = 1:length(showTrials)
    detect = detected(accId).trial(showTrials(cnt)).filter6;
    mag = data(accId).trial(showTrials(cnt)).mag;
    gyro = data(accId).trial(showTrials(cnt)).gyro;
    corrData = zeros(1, length(detect));

    for cnt2 = wSize + 1:length(corrData)
        curRange = cnt2 - wSize + 1:cnt2;
        corrData(cnt2) = corr(mag.dAngle(curRange), gyro.dAngle(curRange));
    end  

    subplot(nRow, nCol, cnt)
    hold on
    plot(mag.diff)
    stem(find(detect), mag.diff(detect), 'LineStyle','none')
    %stem(find(detect), zeros(nnz(detect), 1), 'LineStyle','none')
    title('Diff & Detect')

    subplot(nRow, nCol, nCol + cnt)
    plot(mag.inferMag)
    legend('x', 'y', 'z')
    title('Infered Mag')

    subplot(nRow, nCol, nCol*2+ cnt)
    plot(mag.sample)
    legend('x', 'y', 'z')
    title('Mag samples')

    subplot(nRow, nCol, nCol*3 + cnt)
    hold on
    plot(corrData)
    %stem(range(detect), corrData(detect), 'LineStyle','none')
    title('Correlation')

    subplot(nRow, nCol, nCol*4+ cnt)
    plot(mag.inferAngle)
    title('Angle between infermag ')
    
end