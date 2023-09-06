accId = 1;
showTrials = 1:2;
wSize = 100;
calibrationInterval = (-5*wSize:-wSize);
accName = data(accId).name

% diff 1s : mag - inferred mag using gyro 

figure(11)
clf

nRow = 1;
nCol = length(showTrials);

feature = zeros(2, 3);
feature(1, :) = objectFeature(accId).feature;

for cnt = 1:length(showTrials)
    idx = showTrials(cnt);
    cur = data(accId).trial(idx);

    rmag = cur.rmag;
    gyro = cur.gyro;
    click = cur.detect.sample;
    range = 1:length(calibrationInterval);

    [calm, bias, expmfs] = magcal(rmag.rawSample(range, :));

    rmag.sample = (rmag.rawSample-bias)*calm;
    
    diff = zeros(length(rmag.sample), 3);
    
    for cnt2 = 2:length(rmag.sample)
        euler = gyro.sample(cnt2, :) * 1/100;
        rotm = eul2rotm(euler, 'XYZ');
        val = (rmag.rawSample(cnt2-1, :) - bias)*calm;

        inferredMag = (rotm\(val)')';
        diff(cnt2, :) = (rmag.rawSample(cnt2, :) - bias)*calm - inferredMag;
    end

    diff = sum(diff.^2, 2);
    
    subplot(nRow, nCol, cnt)
    hold on
    plot(diff)
    stem(click, diff(click), 'filled')
    % click = click-100;
    % stem(click, diff(click), 'filled')
    title(accName)
    % ylim([0, 100])
end

return;
%% 
figure(11)
clf

nRow = 1;
nCol = length(1:2);


for cnt = 1:length(showTrials)
    idx = showTrials(cnt);
    cur = data(accId).trial(idx);

    rmag = cur.rmag;
    gyro = cur.gyro;
    click = cur.detect.sample;
    range = 1:length(calibrationInterval);

    [calm, bias, expmfs] = magcal(rmag.rawSample(range, :));

    rmag.sample = rmag.rawSample;
    
    diff = zeros(length(rmag.sample), 3);

    base = (rmag.sample(1, :)-bias) * calm;
    
    for cnt2 = 2:length(rmag.sample)
        euler = gyro.sample(cnt2, :) * 1/100;
        rotm = eul2rotm(euler, 'XYZ');

        if ~isempty(find((click-400) == cnt2, 1))
            calRange = cnt2 + calibrationInterval;
            [calm, bias, ~] = magcal(rmag.sample(calRange, :));

            base = (rmag.sample(cnt2, :)-bias)*calm;
        end

        inferredMag = (rotm\((rmag.sample(cnt2-1, :)-bias)*calm)')';
        diff(cnt2, :) = base - inferredMag;
    end
    
    subplot(nRow, nCol, cnt)
    hold on
    plot(diff)
    % ylim([-150, 150])
    stem(click, diff(click), "filled")
    title(accName)
end

return;
%% Plot bias

figure(17)
clf

for cnt = 1:length(showTrials)
    idx = showTrials(cnt);
    cur = data(accId).trial(idx);

    rmag = cur.rmag;
    click = cur.detect.sample;

    start = 300;
    points = zeros(length(rmag.sample)-300, 3);
    status = false;

    figure(accId * 10 + idx)
    clf

    for cnt2 = start + 1:length(rmag.sample)
        if ~isempty(find(click == cnt2))
            status = ~status;
        end

        if ~isempty(find((click -100 > cnt2) && (click + 100) < cnt2))
            continue;
        end

        range = cnt2 + (-start:-1);

        [~, bias, ~] = magcal(rmag.rawSample(range, :));
        points(cnt2-start, :) = bias;
    end
    

    scatter3(points(:,1), points(:,2), points(:,3));
    xlim([-500, 500])
    ylim([-500, 500])
    zlim([-500, 500])
    xlabel('x')
    ylabel('y')
    zlabel('z')
end