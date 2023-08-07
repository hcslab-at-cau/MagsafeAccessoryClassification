% run('step0_load_data.m')

interval = 100;
start = 100;
extractInterval = (-wSize:wSize);
wSize = 100;
chargingLatency = 200;
startPoint = -1; % start points where accessory was initially detected

rate = 100;
order = 4;
[b.mag, a.mag] = butter(order, 10/rate * 2, 'high');
results = struct();
tic
for cnt = 1:length(data)
    nTrials = length(data(cnt).trial);
    accName = data(cnt).name;

    for cnt2 = 1:nTrials
        tmp = data(cnt).trial(cnt2);
        cur = struct();

        mag = tmp.mag;
        acc = tmp.acc;
        gyro = tmp.gyro;

        accessoryStatus = false; 
        refPoint = -1; % reference point : detection points that has maximum value of magnitude
        curPoints = []; 
        prevPoints = [];
        cnt3 = 1; % count for detection
        

        mag.dAngle = zeros(length(mag.sample), 1);
        mag.inferAngle = zeros(length(mag.sample), 1); 

        for t = 2:start
            mag.dAngle(t) = subspace(mag.sample(t, :)', mag.sample(t - 1, :)');
            euler = gyro.sample(t, :) * 1/rate;
            rotm = eul2rotm(euler, 'XYZ');
            inferredMag = (rotm\(mag.sample(t-1, :))')';
            
            mag.inferAngle(t) = subspace(inferredMag', mag.sample(t, :)');
        end

        for t = 1 + start:length(mag.sample)
            mag.dAngle(t) = subspace(mag.sample(t, :)', mag.sample(t - 1, :)');
            euler = gyro.sample(t, :) * 1/rate;
            rotm = eul2rotm(euler, 'XYZ');
            inferredMag = (rotm\(mag.sample(t-1, :))')';
            
            mag.inferAngle(t) = subspace(inferredMag', mag.sample(t, :)');
        
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
                refPoint = startPoint + find(magnitude == max(magnitude(tarIdx))) - 1;

                startPoint = -1;
                prevPoints = curPoints;
                curPoints = [];
            end
        
            % Feature extraction using charging status
            if refPoint ~= -1 && refPoint + chargingLatency <= t
                extractRange = refPoint + extractInterval;
                
                [featureValue, inferredMag] = func_extract_feature(mag.sample, gyro.sample, extractRange, 4, rate);
                
                if accessoryStatus == false
                    [~, distance] = knnsearch(featureMatrix.train.data, featureValue, 'K', 7, 'Distance', 'euclidean');
                else
                    [~, distance] = knnsearch(featureMatrix.train.data, -featureValue, 'K', 7, 'Distance', 'euclidean');
                end
               
        
                if (accessoryStatus == false && mean(distance) < 20) || (accessoryStatus == true)
                    label = predict(model.knn, featureValue);
                    
                    
                    accessoryStatus = ~accessoryStatus;
                    cur(cnt3).detect = refPoint;
                    cur(cnt3).feature = featureValue;
                    if accessoryStatus == true
                        cur(cnt3).pLabel = label;
                    else
                        cur(cnt3).pLabel = 'detach';
                    end
                    cur(cnt3).label = accName;
                    cnt3 = cnt3 + 1;
                end
                
                refPoint = -1;
            end
        end
        
        
        % Rest 
        if refPoint ~= -1
            extractRange = refPoint + extractInterval;
                
            [featureValue, inferredMag] = func_extract_feature(mag.sample, gyro.sample, extractRange, 4, rate);
            % detectionStatus = false;
        
            
            if accessoryStatus == false
                [~, distance] = knnsearch(featureMatrix.train.data, featureValue, 'K', 7, 'Distance', 'euclidean');
            else
                [~, distance] = knnsearch(featureMatrix.train.data, -featureValue, 'K', 7, 'Distance', 'euclidean');
            end
        
            if (accessoryStatus == false && mean(distance) < 10) || (accessoryStatus == true)
                accessoryStatus = ~accessoryStatus;
                cur(cnt3).detect = refPoint;
                cur(cnt3).feature = featureValue;
                
                if accessoryStatus == true
                    cur(cnt3).pLabel = label;
                else
                    cur(cnt3).pLabel = 'detach';
                end
                cur(cnt3).label = accName;
            end
            
            refPoint = -1;
        end
        results(cnt).trial(cnt2).result = cur;
        results(cnt).trial(cnt2).detection = sum(cnt3-1);
    end
end
toc



