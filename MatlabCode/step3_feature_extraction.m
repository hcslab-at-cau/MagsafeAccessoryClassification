rotOrder = 'XYZ';
usingGroundTruth = false;
extractInterval = (-wSize:wSize);
feature = struct();
featureFigNum = 1;

for cnt = 1:length(data)
    feature(cnt).name = data(cnt).name;
    nTrials = length(data(cnt).trial);

    for cnt2 = 1:nTrials
        cur = struct();
        filter = detected(cnt).trial(cnt2).filter6;    
        mag = data(cnt).trial(cnt2).mag;
        gyro = data(cnt).trial(cnt2).gyro;
        filterIdx = find(filter);
        detectGroundTruth = data(cnt).trial(cnt2).detect.sample;

        for cnt3 = 1:length(filterIdx)
            baseIdx = filterIdx(cnt3);
            range = baseIdx + extractInterval;

            [featureValue1, inferredMag] = func_extract_feature(mag.sample, gyro.sample, range, 1, rate);
            [featureValue2, inferredMagTotal] = func_extract_feature(mag.sample, gyro.sample, range, length(range), rate);

            mags(1, :) = inferredMag;
            mags(2, :) = inferredMagTotal;
            diff(1, :) = featureValue1;
            diff(2, :) = featureValue2;
            m = sqrt(sum(diff(1, :).^2));

            cur(cnt3).baseIdx = baseIdx;
            cur(cnt3).extractRange = range;
            cur(cnt3).mags = mags;
            cur(cnt3).diff = diff;
            cur(cnt3).m = m;
        end
        
        feature(cnt).trial(cnt2).cur = cur;
    end
end

run('plot_feature.m')