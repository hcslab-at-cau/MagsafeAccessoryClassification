% In this feature plot, Using Ground-truth
rotOrder = 'XYZ';
attachInterval = (-wSize*2:wSize);
detachInterval = (-wSize:wSize*2);
usingGroundTruth = true;
feature = struct();
featureFigNum = 2;

for cnt = 1:length(data)
    feature(cnt).name = data(cnt).name;
    nTrials = length(data(cnt).trial);

    for cnt2 = 1:nTrials
        cur = struct();
        tmp = data(cnt).trial(cnt2);
        mag = tmp.mag;
        gyro = tmp.gyro;
        groundTruth = tmp.detect.sample;
        k = 1;

        if length(groundTruth) ~= 10
            disp(cnt2)
        end
        
        for cnt3 = 1:length(groundTruth)
            if mod(cnt3, 2) == 1
                range = groundTruth(cnt3) + attachInterval;
            else
                range = groundTruth(cnt3) + detachInterval;
            end

            [featureValue, inferredMag] = func_extract_feature(mag.sample, gyro.sample, range, 1, rate);
            
            if mod(cnt3, 2) == 1
                cur(k).attach = featureValue; % for attach
            else
                cur(k).detach = featureValue; % for detach
                k = k + 1;
            end
        end

        feature(cnt).trial(cnt2).cur = cur;
    end
end

run('plot_feature.m')