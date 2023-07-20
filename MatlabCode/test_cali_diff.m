attachInterval = (-wSize*2:wSize);
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
    
    subplot(nRow, nCol, k)
    plot(inferredMag)
    legend({'x', 'y', 'z'})
    if cnt == 1
        title('calibrated data')
    else
        title('inferred magnetometer')
    end

    subplot(nRow, nCol, nCol + k)
    plot(mag.sample(range, :))
    title('magnetometer values')

    subplot(nRow, nCol, nCol*2 + k)
    plot(diff)
    title('mag value - inferred mag')    

    k = k + 1;
end