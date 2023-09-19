run('step0_load_data.m')
clear exp
idx = ismember({data.name}, {'None'});
if ~isempty(find(idx, 1))
    data = data(~idx);
end

% run('step4_classification.m')

distanceThreshold = 20;
calibrationThreshold = 2;
interval = 100;
start = 100;
wSize = 100;
extractInterval = (-wSize*2:wSize);

attachInterval = (-wSize*2:wSize);
detachInterval = (-wSize:2*wSize);
calbrationInterval = (-6*wSize:-wSize);

chargingLatency = 200;
startPoint = -1; % start points where accessory was initially detected
chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};

% Model and training data load
mdlDir = 'jaemin9';
mdlPath = '../MatlabCode/models/';
kernelName = 'rbfSVM';


% mdl = load([mdlPath, 'jaeminrbfSVM', '.mat']);
mdl = load('rotMdl.mat');
mdl = mdl.mdl;

featureMatrix.data = mdl.X;
featureMatrix.label = mdl.Y;


% High pass filter 
rate = 100;
order = 4;
[b.mag, a.mag] = butter(order, 10/rate * 2, 'high');
totalAcc = mdl.ClassNames;
totalAcc{end + 1} = 'undefined';

results = struct();
tic
for cnt = 1:length(data)
    nTrials = length(data(cnt).trial);
    accName = data(cnt).name;
    results(cnt).name = accName;

    for cnt2 = 1:nTrials
        tmp = data(cnt).trial(cnt2);
        cur = struct();

        mag = tmp.mag;
        rmag = tmp.rmag;
        acc = tmp.acc;
        gyro = tmp.gyro;

        accessoryStatus = false; % Detach : false, Attach : truez
        refPoint = -1; % reference point : detection points that has maximum value of magnitude
        curPoints = []; 
        prevPoints = [];
        cnt3 = 1; % count for detection
        distanceCnt = 0; % Count for distance filter 

        mag.dAngle = zeros(length(mag.sample), 1);
        mag.inferAngle = zeros(length(mag.sample), 1);
        mag.diffSum = zeros(length(mag.sample), 1);

        lResult = min([length(gyro.sample), length(mag.sample)]);
        
        for t = 2:start
            mag.dAngle(t) = subspace(mag.sample(t, :)', mag.sample(t - 1, :)');
            euler = gyro.sample(t, :) * 1/rate;
            rotm = eul2rotm(euler, 'XYZ');
            inferredMag = (rotm\(mag.sample(t-1, :))')';
            
            mag.inferAngle(t) = subspace(inferredMag', mag.sample(t, :)');
            diff1s = mag.sample(t, :) - (rotm\(mag.sample(t-1, :))')';
            mag.diffSum(t) = sqrt(sum(diff1s.^2, 2));
            
        end

        for t = 1 + start:lResult
            mag.dAngle(t) = subspace(mag.sample(t, :)', mag.sample(t - 1, :)');
            euler = gyro.sample(t, :) * 1/rate;
            rotm = eul2rotm(euler, 'XYZ');
            inferredMag = (rotm\(mag.sample(t-1, :))')';
            
            mag.inferAngle(t) = subspace(inferredMag', mag.sample(t, :)');
            diff1s = mag.sample(t, :) - (rotm\(mag.sample(t-1, :))')';
            mag.diffSum(t) = sqrt(sum(diff1s.^2, 2));
        
            if mod(t, 5) ~= 0
                continue;
            end
        
            range = t + (-interval:-1);
            
            [flag, points] = func_detection(mag, acc, range, accessoryStatus, t);
            
            % Detect accessory attach or detach
            if flag
                curPoints = setdiff(unique([curPoints, points]), prevPoints);
        
                if ~isempty(curPoints)
                    startPoint = curPoints(1);
                end
            end
        
            % Find a reference point for feature extraction.
            if startPoint ~= -1 && startPoint + interval <= t && refPoint == -1
                % select maximum magntiude in points
                magnitude = sum(filtfilt(b.mag, a.mag, mag.sample(startPoint:startPoint+interval-1, :)).^2, 2);
                tarIdx = curPoints - startPoint + 1;

                if tarIdx(end) > 100
                    tarIdx = tarIdx(1):100;
                end
                refPoint = startPoint + find(magnitude == max(magnitude(tarIdx))) - 1;

                startPoint = -1;
                prevPoints = curPoints;
                curPoints = [];
            end
        
            % Feature extraction using charging status
            if refPoint ~= -1 && (refPoint + chargingLatency <= t || t == length(mag.sample))
                extractRange = refPoint + extractInterval;
                calibrationRange = refPoint + calbrationInterval;

                if calibrationRange(1) < 1
                    calibrationRange = 1:calibrationRange(end);
                end

                calibrationRange = calibrationRange(mag.diffSum(calibrationRange) < calibrationThreshold);
                
                % Calibrate magnetometer
                [calm, bias, ~] = magcal(rmag.rawSample(calibrationRange, :));

                % [featureValue, inferredMag] = func_extract_feature((rmag.rawSample-bias)*calm, gyro.sample, extractRange, 4, rate);
                [featureValue, ~] = func_extract_feature_extend((rmag.rawSample-bias)*calm, gyro, extractRange);

                % knnsearch for remove false-positive
                if accessoryStatus == false
                    [~, distance] = knnsearch(featureMatrix.data, featureValue, 'K', 7, 'Distance', 'euclidean');
                else
                    [~, distance] = knnsearch(featureMatrix.data, -featureValue, 'K', 7, 'Distance', 'euclidean');
                end
        
                if mean(distance) < distanceThreshold
                    [preds, scores] = predict(mdl, featureValue);
                    probs = exp(scores) ./ sum(exp(scores),2);

                    % Consider charing status
                    label = func_predict({accName}, preds, probs, totalAcc, chargingAcc);
                    
                    accessoryStatus = ~accessoryStatus;
                    cur(cnt3).detect = refPoint;
                    cur(cnt3).feature = featureValue;
                    
                    cur(cnt3).oLabel = char(preds); % Original Label

                    if accessoryStatus == true
                        cur(cnt3).pLabel = char(label); % Predicted Label
                    else
                        cur(cnt3).pLabel = 'detach';
                    end

                    cur(cnt3).label = accName; % True label
                    cnt3 = cnt3 + 1;
                else
                    distanceCnt = distanceCnt + 1;
                end
                
                refPoint = -1;
            end
        end
        
        results(cnt).trial(cnt2).result = cur;
        results(cnt).trial(cnt2).detection = sum(cnt3-1);
        results(cnt).trial(cnt2).distanceCnt = distanceCnt;
    end
end
toc

run('step5_total_evaluation.m')