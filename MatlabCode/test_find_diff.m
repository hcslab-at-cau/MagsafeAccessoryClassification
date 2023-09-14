clear exp;

accId = 4;
showTrials = 1:2;

wSize = 100;
rate = 100;
calibrationInterval = -6*wSize:-wSize;
attachInterval = -wSize*2:wSize*2;

lowCutoff = 1.0;
highCutoff = 10;

accName = data(accId).name
feature = objectFeature(accId).feature

[b.low, a.low] = butter(4, lowCutoff/rate * 2, 'low');
[b.high, a.high] = butter(4, highCutoff/rate * 2, 'high');

[b.low2, a.low2] = butter(4, 10/rate * 2, 'low');

mdlPath = '../MatlabCode/models/';
mdl = load([mdlPath, 'jaeminlinearSVM', '.mat']);
% mdl = load([mdlPath, 'rotMdl', '.mat']);
mdl = mdl.mdl;

featureMatrix.data = mdl.X;
featureMatrix.label = mdl.Y;


chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};


for cnt = 1:length(showTrials)
    cur = data(accId).trial(showTrials(cnt));
    mag = cur.mag;
    gyro = cur.gyro;
    rmag = cur.rmag;
    rawSample = rmag.rawSample;
    click = cur.detect.sample;

    w = 600; 
    h = 400;

    fig = figure(showTrials(cnt) + length(calibrationInterval)-1);
    % fig.Position(3:4) = [w*2, h];
    clf

    iter = 1:2:length(click);

    nRow = 10;
    nCol = length(iter);
    
    for cnt2 = iter
        t = click(cnt2);

        % Extract range for feature extraction
        range = t + attachInterval;
        if range(1) < 2
            range = 2:range(end);
        end

        if range(end) > length(mag.sample)
            range = range(1):length(mag.sample);
        end
        
        % Extract range for calibration
        calRange = t + calibrationInterval;

        if calRange(1) < 1
            calRange = 1:calRange(end);
        end

        if calRange(end) > length(mag.sample)
            calRange = calRange(1):length(mag.sample);
        end

        % Calibration magnetometer
        [calm, bias, ~] = magcal(rawSample(calRange, :));

        [~, diff1s]= func_get_diff((rawSample-bias)*calm, gyro, calRange);

        diffSum = sum(diff1s.^2, 2);

        % Magnetometer Calibration
        calRange = calRange(diffSum < 5);
        [calm, bias, ~] = magcal(rawSample(calRange, :));
        
        [diffOriginal, diff1s]= func_get_diff((rawSample-bias)*calm, gyro, range);

        diffSum = sum(diff1s.^2, 2);

        % LPF, HPF
        fh = filtfilt(b.high, a.high, diffSum);
        fl = filtfilt(b.low, a.low, diffSum);

        % LPF derivative
        fld = fl(2:end) - fl(1:end-1);
        
        hpfMaxIdx = find(max(fh) == fh);
        tmp = fl((hpfMaxIdx-20):(hpfMaxIdx+20));
        lpfMaxIdx = hpfMaxIdx - 20 -1 + find((max(tmp) == tmp));
        
        sp = -1;
        ep = -1;
        lpfThreshold = 1;

        for cnt3 = 5:length(fh)/2
            if (lpfMaxIdx-cnt3) > 1 && ((fld(lpfMaxIdx-cnt3) * fld(lpfMaxIdx-cnt3-1) < 0)) && sp == -1
                sp = -cnt3;
            end

            if (lpfMaxIdx + cnt3) < length(fld) && ((fld(lpfMaxIdx+cnt3) * fld(lpfMaxIdx+cnt3+1) < 0)) && ep == -1
                ep = cnt3;
            end

            if (ep ~= -1) && (sp ~=-1)
                break;
            end
        end

        % Detect로 간주
        hpfMaxIdxGlobal = range(1) + hpfMaxIdx -1;

        % Calculated diff filtered by hpf, lpf
        range = range(1) + lpfMaxIdx + (sp:ep);
        hpfMaxIdxLocal = hpfMaxIdxGlobal - range(1)+ 1;
        % hpfMaxIdxLocal = hpfMaxIdx;

        [diff, diff1s] = func_get_diff((rawSample-bias)*calm, gyro, range);
        
        % diff = zeros(length(range), 3);
        % diff1s = zeros(length(range), 3);
        % 
        inferAngle = zeros(length(range), 1);
        % sample = (rawSample(range, :) - bias) * calm;
        % refMag = sample(1, :);

        sample = (rawSample(range, :)-bias)*calm;
        for cnt3 = 2:length(range)
            s = range(cnt3);
            
            euler = gyro.sample(s, :) * 1/rate;
            rotm = eul2rotm(euler, 'XYZ');
            
            inferMag = (rotm\(sample(cnt3-1, :))')';
            inferAngle(cnt3) = subspace(inferMag', sample(cnt3, :)');
        end

        idx = find(iter==cnt2);

        % Plotting
        lst = [sp, ep] + lpfMaxIdx;

        subplot(nRow, nCol, idx)
        hold on
        plot(diffOriginal)
        stem(lst, diffOriginal(lst), 'filled')
        title([num2str(t), '-', num2str(length(calRange))])

        subplot(nRow, nCol, nCol + idx)
        hold on
        plot(diffSum)
        title('diff sum')

        lst = [hpfMaxIdx];
        
        subplot(nRow, nCol, nCol*2 + idx)
        hold on
        plot(fh)
        stem(lst, fh(lst), 'filled')
        title(['HPF ', num2str(highCutoff), 'Hz'])
        
        lst = [lpfMaxIdx];

        subplot(nRow, nCol, nCol*3 + idx)
        hold on
        plot(fl)
        stem(lst, fl(lst), 'filled')
        title(['LPF ', num2str(lowCutoff), 'Hz'])
        
        lst = [sp, ep] + lpfMaxIdx;
        
        subplot(nRow, nCol, nCol*4 + idx)
        hold on
        plot(fld)
        stem(lst, fld(lst), 'filled')
        title('filter low derivative')

        % disp([num2str(cnt2), '_', num2str(sp), '_', num2str(ep)])
 
        x = hpfMaxIdxLocal;
        winSize = 1;
        sp = [];
        ep = [];
        minVal = 1000;

        start = 1;

        % angleThreshold = mean(inferAngle(1:(x-start)));
        angleThreshold = 0.02;

        for cnt3 = (x-start):-1:(1+winSize)
            wRange = (cnt3-winSize+1):cnt3;

            if mean(inferAngle(wRange)) > angleThreshold && ~isempty(sp)
                break;
            elseif mean(inferAngle(wRange)) < angleThreshold
                sp(end + 1) = cnt3;
            end
        end

        % angleThreshold = mean(inferAngle((x+start):(length(inferAngle))));

        % for cnt3 = (x+start):(length(inferAngle)-1-winSize)
        %     wRange = cnt3:cnt3+winSize-1;
        % 
        %     if mean(inferAngle(wRange)) < angleThreshold
        %         ep(end + 1) = cnt3;
        %     elseif mean(inferAngle(wRange)) > angleThreshold && ~isempty(ep)
        %         break;
        %     end
        % end

        % if isempty(sp)
        %     sp = 1;
        % else
        %     sp = fix(median(sp));
        % end
        % 
        % if isempty(ep)
        %     ep = length(inferAngle);
        % else
        %     ep = fix(median(ep));
        % end

        
        [~, diff1s] = func_get_diff((rawSample-bias)*calm, gyro, range);
        diffSum = sum(diff1s.^2, 2);

        fl = filtfilt(b.low2, a.low2, diffSum);


        % For test
        filter = (inferAngle < angleThreshold) & (fl < 1);
        sp = find(filter(1:x-1));
        sp = sp(end);

        ep = find(filter(x+1:end));
        ep = x + ep(1);
        
        lst = [sp, x, ep];

        subplot(nRow, nCol, nCol*5 + idx)
        hold on
        plot(diff)
        stem(lst, diff(lst))
        % title([num2str(range(1)), '-', num2str(range(end))])    
        [preds, scores] = predict(mdl, diff(end, :));
        probs = exp(scores) ./ sum(exp(scores),2);
        pLabel = func_predict({accName}, preds, probs, mdl.ClassNames, chargingAcc);

        title([preds{1}, '-->', char(pLabel)])
        
        subplot(nRow, nCol, nCol*6 + idx)
        hold on
        plot(inferAngle)
        stem(lst, inferAngle(lst))
        title('Angle inferMag1s & mag')

        subplot(nRow, nCol, nCol*7 + idx)
        hold on
        plot(diffSum)
        stem(lst, diffSum(lst))
        title('diffsum')
        
        
        subplot(nRow, nCol, nCol*8 + idx)
        hold on
        plot(fl)
        stem(lst, fl(lst))
        title('diffsum LPF')

        range = range(1) - 1 + (sp:ep);

        if isempty(range)
            continue
        end

        [resultDiff, ~] = func_get_diff((rawSample-bias)*calm, gyro, range);
        if mod(cnt2, 2) == 1
            f = resultDiff(end, :);
        else
            f = -resultDiff(end, :);
        end

        [preds, scores] = predict(mdl, f);
        probs = exp(scores) ./ sum(exp(scores),2);
        
        pLabel = func_predict({accName}, preds, probs, mdl.ClassNames, chargingAcc);
        
        [midx, distance] = knnsearch(featureMatrix.data, f, 'K', 11, 'Distance', 'euclidean');

        
        subplot(nRow, nCol, nCol*9 + idx)
        hold on
        plot(resultDiff)
        title([preds{1}, '-->', char(pLabel), ', ',num2str(mean(distance))])

        disp([accName, num2str(cnt2), '->', num2str(f(1)), ',',  num2str(f(2)), ',',  num2str(f(3))])
    end
end
%% Function for get Diff graphs

function [diff, diff1s] = func_get_diff(mag, gyro, range)

diff = zeros(length(range), 3);
diff1s = zeros(length(range), 3);

refMag = mag(range(1), :);

for cnt = 2:length(range)
    t = range(cnt);

    euler = gyro.sample(t, :) * 1/100;
    rotm = eul2rotm(euler, 'XYZ');

    refMag = (rotm\(refMag)')';
    diff(cnt, :) = mag(t, :) - refMag;
    diff1s(cnt, :) = mag(t, :) - (rotm\(mag(t-1, :))')';
end

end
