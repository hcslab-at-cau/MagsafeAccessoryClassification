accId = 1;
showTrials = 1:2;

figure(11)
clf

nCol = length(showTrials);
nRow = 3;

for cnt = 1:length(showTrials)
    detect = detected(accId).trial(showTrials(cnt)).filter6;
    mag = data(accId).trial(showTrials(cnt)).mag;
    gyro = data(accId).trial(showTrials(cnt)).gyro;
    corrData = zeros(3, length(detect));

    for cnt2 = 2:length(mag)
        % Mag의 Rotate vector를 구하고 euler로..
    
    end
    
    for cnt2 = wSize + 1:length(detect)
        curRange = cnt2 - wSize + 1:cnt2;
        for cnt3 = 1:3
            corrData(cnt3, cnt2) = corr(mag.sample(curRange, cnt3), gyro.sample(curRange, cnt3));
        end
    end

    subplot(nRow, nCol, cnt)
    plot(corrData(1, :))
    title('x Corr')

    subplot(nRow, nCol, nCol + cnt)
    plot(corrData(2, :))
    title('y Corr')

    subplot(nRow, nCol, nCol * 2 + cnt)
    plot(corrData(3,:))
    title('z Corr')

end

















