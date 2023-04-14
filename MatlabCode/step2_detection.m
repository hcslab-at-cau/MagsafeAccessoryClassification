result = struct();

wSize = 1 * rate;

magThreshold = 1;
cfarThreshold = .9999;
corrThreshold = .5;
dAngleThreshold = .02;

for cnt = 1:length(data)
    for cnt2 = 1:nTrials
        mag = data(cnt).trial(cnt2).mag;
        acc = data(cnt).trial(cnt2).acc;
        gyro = data(cnt).trial(cnt2).gyro;

        lResult = min([length(mag.magnitude), length(acc.magnitude), ...
            length(mag.dAngle), length(gyro.dAngle)]);

        % Filter 1 : the magnitude of mag should be large enough
        result(cnt, cnt2).filter1 = mag.magnitude(1:lResult) > magThreshold;
        result(cnt, cnt2).filter1(1:wSize) = false;

        % Filter 2 : the delta angle measured from mag should be large enough
        result(cnt, cnt2).filter2 = result(cnt, cnt2).filter1 ...
            & mag.dAngle(1:lResult) > dAngleThreshold;
        
        % Filter 3 : There should be sudden variation in the magnitude of mag
        result(cnt, cnt2).filter3 = result(cnt, cnt2).filter2;
        for cnt3 = find(result(cnt, cnt2).filter3)'
            range = cnt3 + (-wSize:-1);
            result(cnt, cnt2).filter3(cnt3) = func_CFAR(mag.magnitude(range), ...
                mag.magnitude(cnt3), cfarThreshold);
        end

        % Filter 4 : There should be sudden variation in the magnitude of acc
        result(cnt, cnt2).filter4 = result(cnt, cnt2).filter3;
        for cnt3 = find(result(cnt, cnt2).filter4)'
            range = cnt3 + (-wSize:-1);
            result(cnt, cnt2).filter4(cnt3) = func_CFAR(acc.magnitude(range), ...
                acc.magnitude(cnt3), cfarThreshold);
        end        

        % Filter 5 : the delta angles measured from mag and gyro should be
        % different to each other
        result(cnt, cnt2).filter5 = result(cnt, cnt2).filter4;
        for cnt3 = find(result(cnt, cnt2).filter5)'
            range = cnt3 + 1 + (-wSize:-1);
            result(cnt, cnt2).filter5(cnt3) = corr(mag.dAngle(range), gyro.dAngle(range)) < corrThreshold;
        end        
    end
end

figure(2)
clf

idx = 5;

cur = data(idx);
nRow = 6;
nCol = nTrials;
for cnt = 1:nTrials
    mag = cur.trial(cnt).mag;
    acc = cur.trial(cnt).acc;
    gyro = cur.trial(cnt).gyro;
    
    range = 1:length(result(idx, cnt).filter1);        
    
    subplot(nRow, nCol, cnt)
    hold on
    plot(mag.magnitude)              
    stem(range(result(idx, cnt).filter1), mag.magnitude(result(idx, cnt).filter1), 'LineStyle', 'none');    
    
    if cnt == 1
        title([cur.name, ' (mag > 1)'])
    else
        title('mag > 1')
    end
    
    subplot(nRow, nCol, nCol + cnt)
    hold on
    plot(mag.dAngle)
    stem(range(result(idx, cnt).filter2), mag.dAngle(result(idx, cnt).filter2), 'LineStyle', 'none');
    title('Delta angle > .02')

    subplot(nRow, nCol, 2 * nCol + cnt)
    hold on
    plot(mag.magnitude)
    stem(range(result(idx, cnt).filter3), mag.magnitude(result(idx, cnt).filter3), 'LineStyle', 'none');
    title('mag cfar (.9999)')

    subplot(nRow, nCol, 3 * nCol + cnt)
    hold on
    plot(acc.magnitude)
    stem(range(result(idx, cnt).filter4), acc.magnitude(result(idx, cnt).filter4), 'LineStyle', 'none');
    title('acc cfar (.9999)')
    
    subplot(nRow, nCol, 4 * nCol + cnt)    
    hold on
    plot(mag.dAngle)
    plot(gyro.dAngle)
    title('Delta angle')
    legend({'Mag', 'Gyro'})
        
    subplot(nRow, nCol, 5 * nCol + cnt)    
    hold on

    corrData = zeros(1, length(range));
    for cnt2 = wSize + 1:length(corrData)
        curRange = cnt2 - wSize + 1:cnt2;
        corrData(cnt2) = corr(mag.dAngle(curRange), gyro.dAngle(curRange));
    end    
    plot(corrData)

    if sum(result(idx, cnt).filter5 > 0)
        stem(range(result(idx, cnt).filter5), corrData(result(idx, cnt).filter5), ...
            'LineStyle', 'none');
    end
    title('corr < .5')
end