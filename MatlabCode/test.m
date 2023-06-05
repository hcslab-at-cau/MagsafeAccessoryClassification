accId = 1;
trials = 10:10;

nCol = length(trials);
nRow = 7;

figure(21)
clf

for cnt = 1:length(trials)
    objectName = data(accId).name;
    cur = data(accId).trial(trials(cnt));

    mag = cur.mag;
    magValue = mag.sample(:, 2)';
    gyro = cur.gyro;
    detect = detected(accId).trial(trials(cnt)).filter7;
    diff = mag.diff;
    corrData = cur.corr(1, :);
    
    subplot(nRow, nCol, cnt)
    hold on
    plot(mag.sample)
    legend('x', 'y', 'z')
    if(cnt == 1)
        title(objectName)
    else
        title('magnetometer')
    end
    

    subplot(nRow, nCol, nCol + cnt)
    hold on
    plot(detect)
    title('Detect Filter')

    subplot(nRow, nCol, nCol*2 + cnt)
    hold on
    plot(corrData)
    title('Detect Filter')
    
    subplot(nRow, nCol, nCol*3 + cnt)
    hold on
    stem(find(corrData > 0.9), magValue(corrData > 0.9), 'LineStyle','none')
    plot(magValue)
    legend('corr', 'y')
    title('sample with corr > 0.9')

    subplot(nRow, nCol, nCol*4 + cnt)
    hold on
    stem(find(detect), mag.sample(detect), 'LineStyle','none')
    plot(mag.sample)
    legend('filter', 'x', 'y', 'z')
    title('sample with detect filter')

    subplot(nRow, nCol, nCol*5 + cnt)
    hold on
    stem(find(corrData > 0.9), mag.diff(corrData > 0.9), 'LineStyle','none')
    plot(mag.diff)
    legend('corr', 'x', 'y', 'z')
    title('sample with corr > 0.9 in diff')

    subplot(nRow, nCol, nCol*6 + cnt)
    hold on
    stem(find(detect), mag.diff(detect), 'LineStyle','none')
    plot(mag.diff)
    legend('filter', 'x', 'y', 'z')
    title('sample with detect filter in diff')
end
