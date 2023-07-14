rotOrder = 'XYZ';

extractInterval = (-wSize:wSize);
feature = struct();

for cnt = 1:length(data)
    feature(cnt).name = data(cnt).name;
    nTrials = length(data(cnt).trial);
    k = 1;

    for cnt2 = 1:nTrials
        cur = struct();
        filter = detected(cnt).trial(cnt2).filter6;    
        mag = data(cnt).trial(cnt2).mag;
        gyro = data(cnt).trial(cnt2).gyro;
        filterIdx = find(filter);
        lResult = min([length(gyro.sample), length(mag.sample)]);
        disp([num2str(cnt), '_', num2str(cnt2)])

        for cnt3 = 1:length(filterIdx)
            baseIdx = filterIdx(cnt3);
            range = baseIdx + extractInterval;

            [featureValue1, inferredMag] = func_extract_feature(mag.sample, gyro.sample, range, 1, rate);
            [featureValue2, inferredMagTotal] = func_extract_feature(mag.sample, gyro.sample, range, length(range), rate);

            % 1 : 201 sample, 2 : 1 sample, 3 : Real value
            mags(1, :) = inferredMagTotal;
            mags(2, :) = inferredMag;
            diff = featureValue1;
            diff2 = featureValue2;
            m = sqrt(sum(diff.^2));
            
            k = k + 1;

            cur(cnt3).baseIdx = baseIdx;
            cur(cnt3).extractRange = range;
            cur(cnt3).mags = mags;
            cur(cnt3).diff = diff;
            cur(cnt3).diff2 = diff2;
            cur(cnt3).m = m;
        end
        
        feature(cnt).trial(cnt2).cur = cur;
    end
end