clearvars diff

accId = 1;
showTrials = 1:1;

figure('Name', 'differentiate')
clf
nRow = 4;
nCol = length(showTrials);

for cnt = 1:length(showTrials)
    tmp = data(accId).trial(showTrials(cnt));
    mag = tmp.mag;

    subplot(nRow, nCol, cnt)
    plot(mag.sample)

    subplot(nRow, nCol, nCol + cnt)
    plot(diff(mag.sample(:, 1)))

    subplot(nRow, nCol, nCol * 2 + cnt)
    plot(diff(mag.sample(:, 2)))

    subplot(nRow, nCol, nCol * 3 +cnt)
    plot(diff(mag.sample(:, 3)))
    
end