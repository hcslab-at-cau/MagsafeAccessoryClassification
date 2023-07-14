% In this feature plot, Using Ground-truth
rotOrder = 'XYZ';
extractInterval = (-wSize*2:wSize);

feature = struct();

for cnt = 1:length(data)
    feature(cnt).name = data(cnt).name;
    nTrials = length(data(cnt).trial);

    for cnt2 = 1:nTrials
        cur = struct();
        tmp = data(cnt).trial(cnt2);
        mag = tmp.mag;
        gyro = tmp.gyro;
        groundTruth = tmp.detect.sample;
        

        for cnt3 = 1:length(groundTruth)
            range = groundTruth(cnt3) + extractInterval;
            [featureValue, inferredMag] = func_extract_feature(mag.sample, gyro.sample, range, 1, rate);

            cur(cnt3).diff(1, :) = featureValue;
            cur(cnt3).diff(2, :) = featureValue;
        end
        
        feature(cnt).trial(cnt2).cur = cur;
    end
end

run('plot_feature.m')