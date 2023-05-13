accId = 1;
showTrials = 1:2;

figure(11)
clf

nCol = length(showTrials);
nRow = 4;
 
for cnt = 1:length(showTrials)
    detect = detected(accId).trial(showTrials(cnt)).filter6;
    mag = data(accId).trial(showTrials(cnt)).mag;
    gyro = data(accId).trial(showTrials(cnt)).gyro;
    corrData = zeros(4, length(detect));
    threshold = 0.0;

    magEuler = zeros(length(mag.sample), 3);
    magEuler(1, :) = [0, 0, 0];

    for cnt2 = 2:length(mag.sample)
        % Mag의 Rotate vector를 구하고 euler로..
        rotMat = mag.sample(cnt2-1, :).' * pinv(mag.sample(cnt2, :)).';
        euler = rotm2eul(rotMat, 'XYZ');
        magEuler(cnt2, :) = euler;
    end
    
    for cnt2 = wSize + 1:length(detect)
        curRange = cnt2 - wSize + 1:cnt2;

        for cnt3 = 1:3
            corrData(cnt3, cnt2) = corr(magEuler(curRange, cnt3), gyro.sample(curRange, cnt3));
        end
        corrData(4, cnt2) = (corrData(1, cnt2) < threshold) & (corrData(2, cnt2)<threshold) & (corrData(3, cnt2) < threshold);
    end

    subplot(nRow, nCol, cnt)
    hold on
    plot(corrData(1, :))
    title('x Corr')

    subplot(nRow, nCol, nCol + cnt)
    plot(corrData(2, :))
    title('y Corr')

    subplot(nRow, nCol, nCol * 2 + cnt)
    plot(corrData(3,:))
    title('z Corr')


    subplot(nRow, nCol, nCol * 3 + cnt)
    plot(corrData(4,:))
    title('xyz Corr')
end














