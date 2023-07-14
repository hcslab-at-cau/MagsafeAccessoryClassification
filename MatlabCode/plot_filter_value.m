accId = 1;
showTrials = 1:3;
nCol = length(showTrials);
nRow = 4;

figure(5)
clf


for cnt = 1:length(showTrials)
    tmp = data(accId).trial(showTrials(cnt));
    mag = tmp.mag;
    acc = tmp.acc;
    corr = tmp.corr(1, :);

    k = 0;

    subplot(nRow, nCol, nCol*k + cnt)
    plot(mag.magnitude)
    title('magnetometer magnitude')
    k = k + 1;

    subplot(nRow, nCol, nCol*k + cnt)
    plot(mag.dAngle)
    title('magnetometer dAngle')
    k = k + 1;

    subplot(nRow, nCol, nCol*k + cnt)
    plot(mag.inferAngle)
    title('infer angle')
    k = k + 1;

    subplot(nRow, nCol, nCol*k + cnt)
    plot(corr)
    title('corr')
    k = k + 1;
end
