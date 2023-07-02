rotOrder = 'XYZ';

extractInterval = (-wSize:wSize);
feature = struct();
% values = struct();
% values2 = struct();

for cnt = 1:length(data)
    % value = [];
    % value2 = [];
    feature(cnt).name = data(cnt).name;
    % values(cnt).name = data(cnt).name;
    % values2(cnt).name = data(cnt).name;
    nTrials = length(data(cnt).trial);
    k = 1;

    for cnt2 = 1:nTrials
        cur = struct();
        filter = detected(cnt).trial(cnt2).filter6;    
        mag = data(cnt).trial(cnt2).mag;
        gyro = data(cnt).trial(cnt2).gyro;
        filterIdx = find(filter);
        lResult = min([length(gyro.sample), length(mag.sample)]);
        
        for cnt3 = 1:length(filterIdx)
            baseIdx = filterIdx(cnt3);
            range = baseIdx + extractInterval;

            if baseIdx < 2
                range = 2:range(end);
            end

            if range(end) > lResult
                range = range(1):lResult;
            end

            euler = sum(gyro.sample(range, :))* 1/rate;
            rotm = eul2rotm(euler, rotOrder);
            
            refMag = mag.sample(range(1)-1, :);
            inferredMag = zeros(1, 3);
            for cnt4 = range
                euler2 = gyro.sample(cnt4, :) * 1/rate;
                rotm2 = eul2rotm(euler2, rotOrder);
                inferredMag = (rotm2\refMag')';

                refMag = inferredMag;
            end

            mags(1, :) = (rotm \ mag.sample(range(1)-1, :)')';
            mags(2, :) = inferredMag;
            mags(3, :) = mag.sample(range(end), :);
            diff = mags(3, :) - mags(1, :);
            diff2 = mags(3, :) - mags(2, :);
            m = sqrt(sum(diff.^2));
            
            % value = [value;diff];
            % value2 = [value2;diff2];
            k = k + 1;

            cur(cnt3).startIdx = baseIdx;
            cur(cnt3).extractRange = range;
            cur(cnt3).euler = euler;
            cur(cnt3).rotm = rotm;
            cur(cnt3).mags = mags;
            cur(cnt3).diff = diff;
            cur(cnt3).diff2 = diff2;
            cur(cnt3).m = m;
        end
        
        feature(cnt).trial(cnt2).cur = cur;
    end
    % values(cnt).feature = value;
    % values2(cnt).feature = value2;
end