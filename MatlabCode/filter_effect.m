accId = 3;
trials = 1:1;

nCol = length(trials);
nRow = 5;

figure(15)
clf

for cnt = 1:length(trials)
    detect = detected(accId).trial(cnt);
    acc = data(accId).trial(cnt).('acc');
    mag = data(accId).trial(cnt).('mag');

    subplot(nRow, nCol, cnt)
    plot(mag.magnitude)
    title('mag magnitude')
    
    subplot(nRow, nCol, nCol + cnt)
    plot(detect.filter3)
    title('filter 3')

    subplot(nRow, nCol, nCol*2 + cnt);
    plot(acc.magnitude)
    title('acc magnitude')

    subplot(nRow, nCol, nCol*3 + cnt)
    plot(detect.filter4)
    title('filter 4')

    subplot(nRow, nCol, nCol*4 + cnt);
    plot(detect.filter5)
    title('filter 5')
end
