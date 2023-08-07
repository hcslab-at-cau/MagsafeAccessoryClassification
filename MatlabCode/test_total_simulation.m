accId = 10;
trialId = 2;
wSize = 100;
rate = 100;
order = 4;

tmp = data(accId).trial(trialId);
accName = data(accId).name;

mag = tmp.mag;
gyro = tmp.gyro;
acc = tmp.acc;

% For charging status
chargingStatus = zeros(1, length(mag.sample));
if exist('charging', 'var') % Not a charging status
    chargingAcc = {charging.name};
    idx = find(ismember(chargingAcc, accName));
    chargingTime = charging(idx).trial(trialId).charging.sample;
    
    chargingStatus(chargingTime) = 1;
end

chargingLatency = 200;
accessoryStatus = false; % attached : true, detached : false
startPoint = -1; % start points where accessory was initially detected
refPoint = -1; % reference point : detection points that has maximum value of magnitude
curPoints = []; 
prevPoints = [];
totalDetections = [];

tic
interval = 100;
start = 100;
extractInterval = (-wSize:wSize);

[b.mag, a.mag] = butter(order, 10/rate * 2, 'high');
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
        
        refPoint

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

        if accessoryStatus
            s = 'attached';
        else
            s = 'detached';
        end

        disp(['Check for distance!  accessory is ', s])
        disp(['Mean distance : ', num2str(mean(distance))])
        disp(['feature : ' ...
            num2str(featureValue(1)), ', ', num2str(featureValue(2)), ', ', ...
            num2str(featureValue(3))])
        disp(['refPoint : ', num2str(refPoint)])

        if (accessoryStatus == false && mean(distance) < 20) || (accessoryStatus == true)
            label = predict(model.knn, featureValue);
            
            if accessoryStatus == false
                disp(['attach : ', char(label)])
            else
                disp('detach')
                
            end      

            accessoryStatus = ~accessoryStatus;        
            totalDetections(end + 1) = refPoint;
        end
        disp('end!')
        
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
        totalDetections(end + 1) = refPoint;
    end
    
    refPoint = -1;
end


toc

% Plot for results
figure(1)
clf

nRow = 1;
nCol = 1;

subplot(nRow, nCol, 1)
hold on
plot(mag.sample)
stem(totalDetections, mag.sample(totalDetections), 'filled')
