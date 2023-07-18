attachInterval = (-wSize*3:wSize);
attachCalibration = (-wSize*3:-wSize);
detachInterval = (-wSize:wSize*3);

nCol = fix(length(groundTruth)/2);
nRow = 3;
k = 1;

figure(figNum)
clf

for cnt = 1:2:length(groundTruth)
    pnt = groundTruth(cnt);
    range = pnt + attachInterval;
    
    if range(1) < 2
        range = 2:range(end);
    end

    if range(end) > length(gyro)
        range = range(1):length(gyro);
    end

    rawSample = rmag.rawSample;
    calibrationRange = pnt + attachCalibration;

    if calibrationRange(1) < 1
        calibrationRange = 1:calibrationRange(end);
    end

    if calibrationRange(end) > length(rawSample)
        calibrationRange = calibrationRange(1):length(rawSample);
    end
 
    [calMatrix, bias, exp] = magcal(rawSample(calibrationRange, :));

    % refMag = (rawSample(range(1)-1, :)-bias)*calMatrix;
    refMag = (rawSample(range(1)-1, :)-bias);
    inferredMag = zeros(length(range), 3);
    diff = zeros(length(range), 3);

    for cnt2 = 1:length(range)
        t = range(cnt2);
        % sample = (rawSample(t, :)-bias)*calMatrix;
        sample = (rawSample(t, :)-bias);

        euler = gyro(t, :) * 1/rate;
        rotm = eul2rotm(euler, 'XYZ');
        inferredMag(cnt2, :) = (rotm\(refMag)')';
        refMag = inferredMag(cnt2, :);
        diff(cnt2, :) = sample - inferredMag(cnt2, :);
    end



    disp(diff(length(range), :))

    subplot(nRow, nCol, k)
    plot(inferredMag)
    legend({'x', 'y', 'z'})
    if cnt == 1
        title('calibration raw data at detection')
    else
        title('inferred magnetometer')
    end

    subplot(nRow, nCol, nCol + k)
    plot(rmag.sample(range, :))
    title('magnetometer values')

    subplot(nRow, nCol, nCol*2 + k)
    plot(diff)
    title('mag value - inferred mag')    

    k = k + 1;
end