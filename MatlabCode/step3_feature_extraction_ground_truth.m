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
        mag = tmp.mag;
        gyro = tmp.gyro.sample;
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

            % Add Calibration for raw Samples
            % rawSample = mag.rawSample;
            % calRange = groundTruth(cnt3) + attachCalibration;
            % 
            % if calRange(1) < 1
            %     calRange= 1:calRange(end);
            % end
            % 
            % if calRange(end) > length(rawSample)
            %     calRange= calRange(1):length(rawSample);
            % end
            % 
            % if range(1) < 2
            %     range= 2:range(end);
            % end
            % 
            % if range(end) > length(rawSample)
            %     range= range(1):length(rawSample);
            % end
            % 
            % [calibrationMatrix, bias, exp] = magcal(rawSample(calRange, :));
            % refMag = (rawSample(range(1)-1, :)-bias) *calibrationMatrix;
            % inferredMag = zeros(length(range), 3);
            % diff = zeros(length(range), 3);
            % 
            % for cnt4 = 1:length(range)
            %     t = range(cnt4);
            %     sample = (rawSample(t, :)-bias)*calibrationMatrix;
            %     % sample = (rawSample(t, :)-bias);
            % 
            %     euler = gyro(t, :) * 1/rate;
            %     rotm = eul2rotm(euler, 'XYZ');
            %     inferredMag(cnt4, :) = (rotm\(refMag)')';
            %     refMag = inferredMag(cnt4, :);
            %     diff(cnt4, :) = sample - inferredMag(cnt4, :);
            % end
            % 
            % featureValue = diff(length(range), :);
            
            [featureValue, inferredMag] = func_extract_feature(mag.sample, gyro, range, 1, rate);
            
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