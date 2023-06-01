accId = 1;
showTrials = 1:1;

figure(14)
clf

nCol = length(showTrials);
nRow = 6;
threshold = 0.5;

for cnt = 1:length(showTrials)
    detect = detected(accId).trial(showTrials(cnt)).filter7;
    mag = data(accId).trial(showTrials(cnt)).mag;
    gyro = data(accId).trial(showTrials(cnt)).gyro;
    corrData = zeros(1, length(detect));
    mulData = zeros(1, length(detect));
    % corrData = zeros(4, length(detect));
    % corrDataFilter = zeros(2, length(detect));
    % corrDataOriginal = zeros(length(detect));

    % magEuler = zeros(length(mag.sample), 3);
    % 
    % for cnt2 = 2:length(mag.sample)
    %     % Mag의 Rotate vector를 구하고 euler로..
    %     rotMat = (mag.sample(cnt2 - 1, :)*1/rate).' * pinv(mag.sample(cnt2, :) * 1/rate).';
    %     euler = rotm2eul(rotMat, 'ZYX');
    %     magEuler(cnt2, :) = euler;
    % end
    
    % for cnt2 = wSize + 1:length(detect)
    %     curRange = cnt2 - wSize + 1:cnt2;
    % 
    %     for cnt3 = 1:3
    %         corrData(cnt3, cnt2) = corr(magEuler(curRange, cnt3), gyro.sample(curRange, cnt3));
    %     end
    %     corrData(4, cnt2) = (corrData(1, cnt2) < threshold) & ...
    %         (corrData(2, cnt2) < threshold) & (corrData(3, cnt2) < threshold);
    % 
    %     corrDataOriginal(cnt2) = corr(mag.dAngle(curRange), gyro.dAngle(curRange)) < threshold;
    % end
    % 
    % for cnt2 = 1:length(detect)
    %     corrDataFilter(1, cnt2) = corrData(4, cnt2) & detect(cnt2);
    %     corrDataFilter(2, cnt2) = corrDataOriginal(cnt2) & detect(cnt2);
    % end

    interval = 10;

    for cnt2 = interval + 1:length(detect)-10
        curRange = cnt2 - 10 + 1:cnt2+10;

        corrData(cnt2) = corr(mag.dAngle(curRange), mag.inferAngle(curRange));
        
    end

    for cnt2 = 1:length(detect)
        mulData(cnt2) = mag.dAngle(cnt2) * mag.inferAngle(cnt2);
    end

    subplot(nRow, nCol, cnt)
    plot(corrData)
    title('corrData')

    subplot(nRow, nCol, nCol + cnt)
    plot(mulData)
    title('mul')

    subplot(nRow, nCol, nCol* 2 + cnt)
    plot(mag.sample)
    title('Sample')

    subplot(nRow, nCol, nCol * 3 + cnt)
    plot(mag.inferAngle)
    title('infer angle')

    subplot(nRow, nCol, nCol * 4 + cnt)
    plot(mag.dAngle)
    title('dAngle')

    subplot(nRow, nCol, nCol * 5 + cnt)
    plot(detect)
    title('Filter')

    % subplot(nRow, nCol, cnt)
    % hold on
    % plot(corrData(1, :))
    % title('x Corr')
    % 
    % subplot(nRow, nCol, nCol + cnt)
    % plot(corrData(2, :))
    % title('y Corr')
    % 
    % subplot(nRow, nCol, nCol * 2 + cnt)
    % plot(corrData(3,:))
    % title('z Corr')
    % 
    % 
    % subplot(nRow, nCol, nCol * 3 + cnt)
    % plot(corrData(4,:))
    % title('Euler Corr')
    % 
    % subplot(nRow, nCol, nCol * 4 + cnt)
    % plot(corrDataOriginal)
    % title('dAngle Corr')
    % 
    % subplot(nRow, nCol, nCol * 5 + cnt)
    % plot(corrDataFilter(1, :))
    % title('new Filtering')
    % 
    % subplot(nRow, nCol, nCol * 6 + cnt)
    % plot(corrDataFilter(2, :))
    % title('Original Filtering')
end