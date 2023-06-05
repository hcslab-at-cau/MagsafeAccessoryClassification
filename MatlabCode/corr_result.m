accId = 1;
trials = 6:6;

figure(24)
clf

nCol = length(trials);
nRow = 8;

for cnt = 1:length(trials)
    detect7 = detected(accId).trial(trials(cnt)).filter5;
    detect8 = detected(accId).trial(trials(cnt)).filter8;
    mag = data(accId).trial(trials(cnt)).mag;
    gyro = data(accId).trial(trials(cnt)).gyro;
    corrData = data(accId).trial(trials(cnt)).corr;

    range = 1:length(detect7);
    %range = 200:900;
    detect = detect7(range); 

    % modifiedCorr = corrData(2, :);
    % subplot(nRow, nCol, nCol + cnt)
    % hold on
    % plot(modifiedCorr)
    % stem(find(detect8), modifiedCorr(detect8), 'LineStyle','none')
    % title('modified corr')
    
    diff = mag.diff(range, 2);
    cond = mag.inferAngle > 0.05;
    cond = cond(range);

    subplot(nRow, nCol, cnt)
    hold on
    stem(find(cond), diff(cond), 'LineStyle','none')
    stem(find(detect), diff(detect), 'LineStyle','none')
    plot(diff)
    legend({"infer angle > 0.05", "detect", "diff y"})
    title('mag sample diff')

    
    magY = mag.sample(range, 2);
    subplot(nRow, nCol, nCol + cnt)
    hold on
    stem(find(cond), magY(cond), 'LineStyle','none')
    plot(magY)
    title('mag sample')

    newCorr = corrData(1, range);
    subplot(nRow, nCol, nCol*2 + cnt)
    hold on
    plot(newCorr)
    stem(find(detect), newCorr(detect), 'LineStyle','none')
    title('new corr')

    subplot(nRow, nCol, nCol*3 + cnt)
    plot(mag.inferAngle(range))
    title('infer angle')

    subplot(nRow, nCol, nCol * 4 + cnt)
    plot(mag.dAngle(range))
    title('mag dAngle')

    subplot(nRow, nCol, nCol * 5 + cnt)
    plot(gyro.dAngle(range))
    title('gyro dAngle')

    subplot(nRow, nCol, nCol * 6 + cnt)
    plot(detect7(range))
    title('New Filter > 0.9')

    subplot(nRow, nCol, nCol * 7 + cnt)
    plot(detect8(range))
    title('Modified corr > 0.5')
    
end