accId = 11;
trialId = 4;
attachInterval = (fix(-wSize*1.5):wSize);

% attachInterval = (-wSize:wSize);

tmp = data(accId).trial(trialId);
mag = tmp.mag;
gyro = tmp.gyro.sample;
filter = detected(accId).trial(trialId).filter6;
nPoints = find(filter)';


for cnt = 1:length(nPoints)
    point = nPoints(cnt);
    
    range = point + attachInterval;
    
    if range(1) < 2
        range = 2:range(end);
    end

    if range(end) > length(gyro)
        range = range(1):length(gyro);
    end

    refMag = mag.sample(range(1)-1, :);
    inferredMag = zeros(length(range), 3);
    diff = zeros(length(range), 3);

    for cnt2 = 1:length(range)
        t = range(cnt2);

        euler = gyro(t, :) * 1/rate;
        rotm = eul2rotm(euler, 'XYZ');
        inferredMag(cnt2, :) = (rotm\(refMag)')';
        refMag = inferredMag(cnt2, :);
        diff(cnt2, :) = mag.sample(t, :) - inferredMag(cnt2, :);
    end

    disp(diff(end, :))

    figure(cnt)
    clf

    subplot(3, 1, 1)
    plot(inferredMag)
    legend({'x', 'y', 'z'})
    if cnt == 1
        title('calibrated data')
    else
        title('inferred magnetometer')
    end

    subplot(3, 1, 2)
    plot(mag.sample(range, :))
    title('magnetometer values')

    subplot(3, 1, 3)
    plot(diff)
    title('mag value - inferred mag')    
end