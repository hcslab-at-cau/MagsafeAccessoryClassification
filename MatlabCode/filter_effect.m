accId = 3;
trials = 1:1;

nCol = length(trials);
nRow = 4;

figure(15)
clf

for cnt = 1:length(trials)
    detect = detected(accId).trial(cnt);
    acc = data(accId).trial(cnt).('acc');
    
    subplot(nRow, nCol, cnt)
    plot(detect.filter3)
    title('filter 3')

    subplot(nRow, nCol, nCol + cnt);
    plot(acc.cfarData)
    title('cfar data')

    subplot(nRow, nCol, nCol*2 + cnt)
    plot(detect.filter4)
    title('filter 4')

    subplot(nRow, nCol, nCol*3 + cnt);
    plot(detect.filter5)
    title('filter 5')
end
