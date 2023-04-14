accId = 2;
cur = data(accId);



result = struct();
for cnt = 1:nTrials
    mag = cur.trial(cnt).mag;
    acc = cur.trial(cnt).mag;
    gyro = cur.trial(cnt).gyro;
            
    
    lResult = min([length(mag.magnitude), length(acc.magnitude), length(mag.dAngle), length(gyro.dAngle)]);
    
    result(cnt).mCFAR = false(lResult, 1);
    result(cnt).aCFAR = false(lResult, 1);
    for cnt2 = cfarWSize + 1:lResult
        range = cnt2 + (-cfarWSize:-1);

        result(cnt).mCFAR(cnt2) = func_CFAR(mag.magnitude(range), mag.magnitude(cnt2), cfarThreshold);
        result(cnt).aCFAR(cnt2) = func_CFAR(acc.magnitude(range), acc.magnitude(cnt2), cfarThreshold);
    end
        
    result(cnt).distance = zeros(lResult, 1);
    for cnt2 = corrWSize:lResult
        range = cnt2 + (-corrWSize + 1:0);
        result(cnt).distance(cnt2) = pdist([mag.dAngle(range), gyro.dAngle(range)]', corrDistanceType);
    end    
    
    result(cnt).detected = result(cnt).mCFAR ...
        & mag.magnitude(1:lResult) > magThreshold ...
        & result(cnt).aCFAR ...
        & result(cnt).distance > distanceThreshold ...
        & mag.dAngle(1:lResult) > dAngleThreshold;
end


figure(2)
clf

nRow = 5;
nCol = nTrials;
for cnt = 1:nTrials
    mag = cur.trial(cnt).mag;
    acc = cur.trial(cnt).mag;
    
    range = 1:length(result(cnt).mCFAR);        
    
    subplot(nRow, nCol, cnt)
    hold on
    plot(mag.magnitude)          
    
    tmp = result(cnt).mCFAR & mag.magnitude(range) > magThreshold;    
    stem(range(tmp), mag.magnitude(tmp), 'LineStyle', 'none');
    legend('mag w/ HPF')
    
    if cnt == 1
        title(cur.name)
    end
    
    subplot(nRow, nCol, nCol + cnt)
    hold on
    plot(acc.magnitude)
    
    tmp = tmp & result(cnt).aCFAR;
    stem(range(tmp), acc.magnitude(tmp), 'LineStyle', 'none');       
    legend('acc w/ HPF')
    
    subplot(nRow, nCol, 2 * nCol + cnt)    
    hold on
    plot(result(cnt).distance)
    
    tmp = tmp & result(cnt).distance > distanceThreshold;
    stem(range(tmp), result(cnt).distance(tmp), 'LineStyle', 'none');       
    legend('corr distance')
    
    
    subplot(nRow, nCol, 3 * nCol + cnt)
    hold on
    plot(mag.dAngle)    
    tmp = tmp & mag.dAngle(range) > dAngleThreshold;
    stem(range(tmp), mag.dAngle(tmp), 'LineStyle', 'none');       
    legend('angle')

    
    subplot(nRow, nCol, 4 * nCol + cnt)
    plot(result(cnt).detected)
    legend('detected')
end