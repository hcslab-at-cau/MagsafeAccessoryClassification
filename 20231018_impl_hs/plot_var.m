figure(130)
clf
accId = 6;
nRow = length(ori(accId).trial);
nCol = 1;

for trial = 1:length(ori(accId).trial)
    cur = ori(accId).trial(trial);
    mag = cur.rmag;
    gyro = cur.gyro;
    detected = cur.detect.sample;
    
    [calm, bias, ~] = magcal(mag.sample(1:500, :));
    mag.sample = (mag.sample-bias)*calm;
    
    refMag = mag.sample(1, :);
    diff = zeros(length(mag.sample) , 3);
    varSum = zeros(length(mag.sample) , 3);
    varInterval = 10;

    for cnt = 1 + 1:length(mag.sample)
        euler = gyro.sample(cnt, :) * 0.01;
        rotm = eul2rotm(euler, 'XYZ');

        % refMag = (rotm\(refMag)')';

        refMag = (rotm\(mag.sample(cnt-1, :))')';
        diff(cnt, :) = mag.sample(cnt, :) - refMag;

        if cnt > varInterval
            varSum(cnt, :) = sum(var(diff((cnt-varInterval):cnt, :)));
        end
    end

    
    subplot(nRow, nCol, trial)
    plot(varSum)
    hold on 
    hx = xline(detected);
    title(ori(accId).name)
    ylim([0 2])
end

return;

%% 
figure(12)
clf

accId = 14;
nRow = 5;
nCol = length(ori(accId).trial);

for trial = 1:length(ori(accId).trial)
    cur = ori(accId).trial(trial);
    mag = cur.rmag;
    gyro = cur.gyro;
    detected = cur.detect.sample;
    
    [calm, bias, ~] = magcal(mag.sample(1:500, :));
    mag.sample = (mag.sample-bias)*calm;


    for cnt = 1:2:length(detected)
        detect = detected(cnt);

        range = max(1, detect-500):min(length(mag.sample), detect+100);

        varSum = zeros(length(range), 1);
        meanSum = zeros(length(range), 3);
        
        varInterval = 5;
        diff = zeros(length(range), 3);

        refMag = mag.sample(range(1), :);

        for cnt2 = 2:length(range)
            pnt = range(cnt2);
            euler = gyro.sample(pnt, :) * 0.01;
            rotm = eul2rotm(euler, 'XYZ');

            refMag = (rotm\(refMag)')';
            % refMag = (rotm\(mag.sample(pnt-1, :))')';
            diff(cnt2, :) = mag.sample(pnt, :) - refMag;


            if cnt2 > varInterval
                meanSum(cnt2, :) = sum(abs(mean(diff((cnt2-varInterval):cnt2, :))));
                varSum(cnt2, :) = sum(var(diff((cnt2-varInterval):cnt2, :)));
            end
        end
        
        diffMagnitude = sqrt(sum(diff.^2, 2));
        
        subplot(nRow, nCol, (ceil(cnt/2)-1) * nCol + trial)
        plot(varSum)
        % title(ori(accId).name)
        
        title(sum(var(diff(100:200, :))))
        ylim([0 100])
    end
end