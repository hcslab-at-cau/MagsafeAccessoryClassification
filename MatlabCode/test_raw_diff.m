figNum = 40;
attachInterval = (-wSize*3:wSize);
attachCalibration = (-wSize*3:-wSize);
detachInterval = (-wSize:wSize*3);
% Validate for feature extract method
accId = 1;
trialId = 8;

tmp = data(accId).trial(trialId);
mag = tmp.rmag;
groundTruth = tmp.detect.sample;
gyro = tmp.gyro.sample;
disp(data(accId).name)

nRow = 3;

for cnt = 1:2:length(groundTruth)
    figure(figNum + cnt)
    clf
    
    pnt = groundTruth(cnt);
    range = pnt + attachInterval;
    
    if range(1) < 2
        range = 2:range(end);
    end

    if range(end) > length(gyro)
        range = range(1):length(gyro);
    end

    rawSample = mag.rawSample;
    [calMatrix, bias, exp] = magcal(rawSample(pnt + attachCalibration, :));

    refMag = (rawSample(range(1)-1, :)-bias)*calMatrix;
    inferredMag = zeros(length(range), 3);
    diff = zeros(length(range), 3);

    for cnt2 = 1:length(range)
        t = range(cnt2);
        sample = (rawSample(t, :)-bias)*calMatrix;

        euler = gyro(t, :) * 1/rate;
        rotm = eul2rotm(euler, 'XYZ');
        inferredMag(cnt2, :) = (rotm\(refMag)')';
        refMag = inferredMag(cnt2, :);
        diff(cnt2, :) = sample - inferredMag(cnt2, :);
    end

    disp(diff(length(range), :))

    subplot(nRow, 1, 1)
    plot(inferredMag)
    legend({'x', 'y', 'z'})
    title('inferred magnetometer using gyroscope')

    subplot(nRow, 1, 2)
    plot(mag.sample(range, :))
    title('magnetometer values')

    subplot(nRow, 1, 3)
    plot(diff)
    title('mag value - inferred mag')    
end