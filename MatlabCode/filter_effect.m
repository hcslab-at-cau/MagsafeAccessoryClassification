accId = 2;
trials = 5:5;

nCol = length(trials);
nRow = 7;

figure(15)
clf

for cnt = 1:length(trials)
    detect = detected(accId).trial(trials(cnt));
    acc = data(accId).trial(trials(cnt)).('acc');
    mag = data(accId).trial(trials(cnt)).('mag');
    
    k = 0;
    
    subplot(nRow, nCol, nCol * k + cnt)
    plot(detect.filter2)
    title('filter 2')
    k = k + 1;

    subplot(nRow, nCol, nCol * k + cnt)
    plot(detect.filter3)
    title('filter 3')
    k = k + 1;

    subplot(nRow, nCol, nCol * k + cnt)
    plot(detect.filter4)
    title('filter 4')
    k = k + 1;

    subplot(nRow, nCol, nCol * k + cnt);
    plot(detect.filter5)
    title('filter 5')
    k = k + 1;

    subplot(nRow, nCol, nCol * k + cnt);
    plot(detect.filter6)
    title('filter 6')
    k = k + 1;

    subplot(nRow, nCol, nCol * k + cnt);
    plot(detect.filter7)
    title('filter 7')
    k = k +1;

    subplot(nRow, nCol, nCol * k + cnt)
    plot(mag.inferAngle)
    title('Angle between infermag ')
end
