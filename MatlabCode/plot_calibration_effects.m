if ~newApp
    return;
end

accId = 3;
showTrials = 1:2;
accName = data(accId).name
feature = objectFeature(accId).feature;
wSize = 100;
rate = 100;

[b.mag, a.mag] = butter(4, 5/100 * 2, 'high');

calibrationInterval = -5*wSize:-wSize;
attachInterval = -wSize*2:wSize;

coef = ones(1, 20)/20;

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
    fig.Position(3:4) = [w*2, h];
    clf

    iter = 1:1:length(click);

    nRow = 3;
    nCol = length(iter);

    % Initially calibrate
    calRange = 1:length(calibrationInterval);
    [calm, bias, exp] = magcal(rawSample(calRange, :));

    rmag.sample = (rawSample-bias)*calm;

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

        diff1 = [];

        for cnt3 = 2:length(range)
            t = range(cnt3);

            euler = gyro.sample(cnt3, :) * 1/rate;
            rotm = eul2rotm(euler, 'XYZ');

            prevMag = (rmag.rawSample(t-1, :)-bias)*calm;
            curMag = (rmag.rawSample(t, :)-bias)*calm;
            
            diff1(end + 1, :) = curMag - (rotm\(prevMag)')';
        end

        diff1 = sum(diff1.^2, 2);
        
        % Select calibration range
        % calRange = calRange(diff1 < 5);

        disp([num2str(cnt), '_', num2str(cnt2), '_', num2str(length(calRange))])

        % Calibration magnetometer
        [calm, bias, ~] = magcal(rawSample(calRange, :));
        
        refMag = zeros(3, 3); 
        inferredMag = zeros(3, 3);
        diff = zeros(length(range), 3, 3);
        sample = zeros(length(range), 3, 3);

        sample(:, :, 1) = mag.sample(range, :);
        sample(:, :, 2) = (rawSample(range, :) - bias) * calm;
        sample(:, :, 3) = rmag.sample(range, :);

        for cnt3 = 1:3
            refMag(cnt3, :) = sample(1, :, cnt3);
        end
        
        for cnt3 = 1:length(range)
            s = range(cnt3);

            for cnt4 = 1:3
                euler = gyro.sample(s, :) * 1/rate;
                rotm = eul2rotm(euler, 'XYZ');
                refMag(cnt4, :) = (rotm\(refMag(cnt4, :))')';

                diff(cnt3, :, cnt4) = sample(cnt3, :, cnt4)-refMag(cnt4, :); 
            end
        end

        idx = find(iter==cnt2);

        subplot(nRow, nCol, idx)
        hold on
        plot(diff(:, :, 1))
        title('sensor calibrated data')
        
        subplot(nRow, nCol, nCol + idx)
        plot(diff(:, :, 2))
        title(num2str(length(calRange)))

        subplot(nRow, nCol, nCol*2 + idx)
        plot(diff(:, :, 3))
        title('calibrate at initially')
    end
    
end


