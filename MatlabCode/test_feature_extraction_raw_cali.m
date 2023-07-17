% In this feature plot, Using Ground-truth
rotOrder = 'XYZ';
attachInterval = (-wSize*3:wSize);
attachCalibration = (-wSize*3:-wSize);
detachInterval = (-wSize:wSize*2);
usingGroundTruth = true;
feature = struct();
featureFigNum = 3;

for cnt = 1:length(data)
    feature(cnt).name = data(cnt).name;
    nTrials = length(data(cnt).trial);

    for cnt2 = 1:nTrials
        cur = struct();
        tmp = data(cnt).trial(cnt2);
        mag = tmp.rmag;
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

            
            if range(1) < 2
                range = 2:range(end);
            end

            if range(end) > length(gyro.sample)
                range = range(1):length(gyro.sample);
            end
            

            rawSample = mag.rawSample;

            calRange = groundTruth(cnt3) + attachCalibration;
            [caliMat, bias, exp] = magcal(rawSample(calRange, :));
            
            refMag = rawSample(range(1)-1, :)-bias;
            for t = 1:length(range)

                sample = (rawSample(range(t), :) - bias);
                euler = gyro.sample(range(t), :)*1/rate;
                rotm = eul2rotm(euler, 'XYZ');

                inferredMag = (rotm\refMag')';
                refMag = inferredMag;
            end

            featureValue = sample - inferredMag;

            
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