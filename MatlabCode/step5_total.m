% run('step0_load_data.m')
clear exp
idx = ismember({data.name}, {'None'});
if ~isempty(find(idx, 1))
    data = data(~idx);
end

interval = 100;
start = 500;
wSize = 100;

distanceThreshold = 40;
calibrationThreshold = 2;

extractInterval = (-wSize*2:wSize);
calbrationInterval = (-6*wSize:-1*wSize);
chargingLatency = 200;
chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};

% Model and training data load
mdlPath = '../MatlabCode/models/';
mdl = load([mdlPath, 'rotMdl2', '.mat']);
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

parfor cnt = 1:length(data)
    nTrials = length(data(cnt).trial);
    accName = data(cnt).name;
    results(cnt).name = accName;

    startPoint = -1; % start points where accessory was initially detected

    for cnt2 = 1:nTrials
        tmp = data(cnt).trial(cnt2);
        cur = struct();

        mag = tmp.rmag;
        acc = tmp.acc;
        gyro = tmp.gyro;

        accessoryStatus = false; % Detach : false, Attach : true
        refPoint = -1; % reference point : detection points that has maximum value of magnitude
        curPoints = []; 
        prevPoints = [];
        cnt3 = 1; % count for detection

        lResult = min([length(gyro.sample), length(mag.sample)]);
        
        for t = start + 1:5:lResult
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
               
                % calibrationRange = refPoint + calbrationInterval;
                % 
                % if calibrationRange(1) < 1
                %     calibrationRange = 1:calibrationRange(end);
                % end

                % calibrationRange = calibrationRange(mag.diffSum(calibrationRange) < calibrationThreshold);
                
                % Calibrate magnetometer
                % [calm, bias, ~] = magcal(mag.rawSample(calibrationRange, :));
                % mag.sample = (mag.rawSample-bias)


                extractRange = func_extract_range(mag.sample, gyro, extractRange, refPoint);

                % knnsearch for remove false-positive
                [featureValue, ~] = func_extract_feature(mag.sample, gyro.sample, extractRange, accessoryStatus);

                [preds, scores] = predict(mdl, featureValue);
                probs = exp(scores) ./ sum(exp(scores),2);

                % Consider charing status
                label = func_predict({accName}, preds, probs, totalAcc, chargingAcc);
                indices = ismember(featureMatrix.label, label);
                
                [~, distance] = knnsearch(featureMatrix.data(indices, :), featureValue, 'K', 7, 'Distance', 'euclidean');
        
                if mean(distance) < distanceThreshold
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
                end
                
                refPoint = -1;
            end
        end
        
        results(cnt).trial(cnt2).result = cur;
        results(cnt).trial(cnt2).detection = sum(cnt3-1);
    end
end
toc

run('step5_total_evaluation.m')

return;

%% Using ground-truth
clear exp;

parfor cnt = 1:length(data)
    
end


%% Using diff

% run('step0_load_data.m')
clear exp
idx = ismember({data.name}, {'None'});
if ~isempty(find(idx, 1))
    data = data(~idx);
end

interval = 100;
wSize = 100;
extractInterval = (wSize:wSize*3);
shakeInterval = (-3*wSize:-1);
diffThreshold = 5;

chargingLatency = 200;
chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};

% High pass filter 
rate = 100;
order = 4;
[b.mag, a.mag] = butter(order, 10/rate * 2, 'high');
totalAcc = {objectFeature.name};
totalAcc{end + 1} = 'undefined';

results = struct();
tic

parfor cnt = 1:length(data)
    nTrials = length(data(cnt).trial);
    accName = data(cnt).name;
    results(cnt).name = accName;

    startPoint = -1; % start points where accessory was initially detected
    refPoint = -1;

    for cnt2 = 1:nTrials
        tmp = data(cnt).trial(cnt2);
        cur = struct();

        mag = tmp.mag;
        rmag = tmp.rmag;
        acc = tmp.acc;
        gyro = tmp.gyro;

        accessoryStatus = false; % Detach : false, Attach : truez
        refCandidates = []; % reference point : detection points that has maximum value of magnitude
        curPoints = []; 
        prevPoints = [];
        cnt3 = 1; % count for detection
        distanceCnt = 0; % Count for distance filter
        shakePoint = [-1, -1];
        shakePoints = [];
        shakeFlag = false;

        % Find calibration range
        start = 500;
        while true
            wRange = start + (-100:-1);

            flag = func_detect_shaking(acc, gyro, wRange);

            if flag
                start = start + 10;
            else
                start = start - 100;
                break
            end
        end

        [calm, bias, ~] = magcal(rmag.rawSample(1:start, :));
        mag.sample = (rmag.rawSample-bias) * calm;

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
            % Preprocess part
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
            
            % Detection part : find a points
            if flag
                curPoints = setdiff(unique([curPoints, points]), prevPoints);
        
                if ~isempty(curPoints)
                    startPoint = curPoints(1);
                end
            end
        
            % Detection part : pick detection points
            if startPoint ~= -1 && startPoint + interval <= t
                % select maximum magntiude in points
                magnitude = sum(filtfilt(b.mag, a.mag, mag.sample(startPoint:startPoint+interval-1, :)).^2, 2);
                tarIdx = curPoints - startPoint + 1;

                if tarIdx(end) > 100
                    tarIdx = tarIdx(1):100;
                end
                refCandidates(end + 1) = startPoint + find(magnitude == max(magnitude(tarIdx))) - 1;

                startPoint = -1;
                prevPoints = curPoints;
                curPoints = [];
            end

            % Shaking detection part
            if ~accessoryStatus && refPoint == -1
                % Attach : Shaking detection is required
                wRange = t + (-100:-1);           
                flag = func_detect_shaking(acc, gyro, wRange);
                
                if flag
                    % Extract closest detection points
                    wRange = t + shakeInterval;
                    indices = find(ismember(wRange, refCandidates));
                    
                    if ~isempty(indices)
                        refPoint = wRange(indices(end));
                        shakePoint(1) = t;
                    end
                end
            elseif ~accessoryStatus && refPoint ~= -1
                % To extract shaking range
                wRange = t + (-100:-1);
                
                flag = func_detect_shaking(acc, gyro, wRange);

                if flag
                    shakePoint(2) = t;
                else
                    shakeFlag = true;
                end
            elseif accessoryStatus && refPoint == -1 && shakePoint(2) < refCandidates(end)
                % Detach : Shaking detection x
                refPoint = refCandidates(end);
            end

        
            % Diff calculation part
            if refPoint ~= -1 && (refPoint + length(shakeInterval) <= t || t == length(mag.sample))...
                    && (shakeFlag || accessoryStatus)
                if accessoryStatus == false
                    % Attach : Using diff 1s comparsion, predict label      
                    if (shakePoint(1) >= (shakePoint(2) - 100)) || shakePoint(1) == -1
                        refPoint = -1;
                        shakeFlag = false;
                        continue;
                    end

                    extractRange = shakePoint(1):(shakePoint(2)-100);
                    [flag, probs] = func_predict_diff(mag, gyro, objectFeature, extractRange);
                    
                    if ~flag
                        refPoint = -1;
                        shakeFlag = false;
                        continue;
                    end

                    pLabel = objectFeature(find(max(probs) == probs)).name;
                    label = func_predict({accName}, {pLabel}, probs, totalAcc, chargingAcc);

                else
                    % Detach : Diff 1s is less than threshold.
                    extractRange = refPoint + extractInterval;

                    if extractRange(end) > length(mag.sample)
                        extractRange = extractRange(1):length(mag.sample);
                    end

                    diff1s = zeros(length(extractRange), 3);

                    for k = 1:length(extractRange)
                        euler = gyro.sample(extractRange(k), :) * 1/100;
                        rotm = eul2rotm(euler, 'XYZ');

                        diff1s(k, :) = mag.sample(extractRange(k), :) - (rotm\(mag.sample(extractRange(k)-1, :))')';
                    end

                    

                    if mean(var(diff1s)) > diffThreshold
                        refPoint = -1;
                        shakeFlag = false;
                        continue;
                    end
                end
                
                cur(cnt3).detect = refPoint;
                cur(cnt3).label = accName;

                if ~accessoryStatus
                    cur(cnt3).pLabel = char(label);
                else
                    cur(cnt3).pLabel = 'detach';
                end
                
                shakePoints(end+1:end+2) = shakePoint;
                accessoryStatus = ~accessoryStatus;
                cnt3 = cnt3 + 1;
                refPoint = -1;
                shakeFlag = false;
            end
        end
        
        results(cnt).trial(cnt2).result = cur;
        results(cnt).trial(cnt2).detection = sum(cnt3-1);
        results(cnt).trial(cnt2).candidates = refCandidates;
        results(cnt).trial(cnt2).shakePoints = shakePoints;
        results(cnt).trial(cnt2).start = start;
    end
end
toc

run('step5_total_evaluation.m')
%% Detection of shaking
function flag = func_detect_shaking(acc, gyro, range)
flag= false;
rate = 100;
[b.high, a.high] = butter(4, 1/rate * 2, 'high');

accHPF = sum(filtfilt(b.high, a.high, acc.sample(range, :)), 2);
gyroHPF = sum(filtfilt(b.high, a.high, gyro.sample(range, :)), 2);

filter = abs(gyroHPF) > 5;

res = find(filter, 1);

if ~isempty(res)
    flag = true;
end

end