accId = 2;
trialId = 8;
wSize = 100;
rate = 100;
order = 4;

tmp = data(accId).trial(trialId);
accName = data(accId).name;

mag = tmp.mag;
gyro = tmp.gyro;
acc = tmp.acc;

% For charging status
chargingAcc = {charging.name};
chargingStatus = zeros(1, length(mag.sample));
if ~isempty(find(ismember(chargingAcc, accName))) % Not a charging status
    idx = find(ismember(chargingAcc, accName));
    chargingTime = charging(idx).trial(trialId).charging.sample;
    
    chargingStatus(chargingTime) = 1;
end

chargingLatency = 200;
accessoryStatus = false; % attached : true, detached : false
detectionStatus = false;
startPoint = -1; % start points where accessory was initially detected
refPoint = -1; % reference point : detection points that has maximum value of magnitude
curPoints = []; 
prevPoints = [];
totalDetections = [];


tic
interval = 100;
start = 100;
extractInterval = (-wSize:wSize);

[b.magh, a.magh] = butter(order, 10/rate * 2, 'high');
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
        % curPoints = unique([curPoints, points]);
        curPoints = setdiff(unique([curPoints, points]), prevPoints);
        % disp('In if')
        % t
        % curPoints
        % disp('end')

        if ~isempty(curPoints)
            startPoint = curPoints(1);
        end
    end

    % Find a reference point for feature extraction.
    if startPoint ~= -1 && startPoint + interval <= t && refPoint == -1
        % select maximum magntiude in points
        magnitude = sum(filtfilt(b.magh, a.magh, mag.sample(startPoint:startPoint+interval-1, :)).^2, 2);
        tarIdx = curPoints - startPoint + 1;
        
        startPoint + tarIdx
    
        refPoint = startPoint + find(magnitude == max(magnitude(tarIdx))) - 1;

        % refPoint
        % t
        % curPoints
        % 
        startPoint = -1;
        prevPoints = curPoints;
        curPoints = [];
    end

    % Feature extraction using charging status
    if refPoint ~= -1 && refPoint + chargingLatency <= t
        extractRange = refPoint + extractInterval;
        
        [featureValue, inferredMag] = func_extract_feature(mag.sample, gyro.sample, extractRange, 4, rate);
        % detectionStatus = false;

        
        if accessoryStatus == false
            [~, distance] = knnsearch(featureMatrix.train.data, featureValue, 'K', 7, 'Distance', 'euclidean');
        else
            [~, distance] = knnsearch(featureMatrix.train.data, -featureValue, 'K', 7, 'Distance', 'euclidean');
        end

        % featureValue
        % refPoint
        % mean(distance)

        if (accessoryStatus == false && mean(distance) < 10) || (accessoryStatus == true)
            accessoryStatus = ~accessoryStatus;
            totalDetections(end + 1) = refPoint;
        end
        
        refPoint = -1;
    end
end

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



function [result, detectPoints] = func_detection(mag, acc, range, status, t)
result = false;
detectPoints = [];
interval = 100;

% Detection thresholds
magThreshold = 1;
cfarThreshold = .9999;
corrThreshold = .9;
dAngleThreshold = .01;

% High-pass filter args
rate = 100;
order = 4;
[b.magh, a.magh] = butter(order, 10/rate * 2, 'high');
[b.acch, a.acch] = butter(order, 40/rate * 2, 'high');

% Filter 1 : Magnitude > 1
wRange = -100 + range(1):range(end);

if wRange(1) < 1
    wRange = 1:wRange(end);
end

wRangeSize = 1:length(wRange);
magnitude.mag = sum(filtfilt(b.magh, a.magh, mag.sample(wRange, :)).^2, 2);

filter1 = magnitude.mag(wRangeSize(end-99:end)) > magThreshold;
if isempty(find(filter1))
    return
end


% Filter 2 : dAngle > 0.01
filter2 = filter1 & mag.dAngle(range) > dAngleThreshold;
if isempty(find(filter2))
    return
end

% Filter 3 : mag magnitude CFAR 
filter3 = filter2;
for cnt3 = find(filter3)'
    innerRange = 100 + cnt3 + (-100:-1);
    
    % disp([num2str(cnt3), '_', num2str(innerRange(1)), '_', num2str(innerRange(end))])
    if innerRange(end) > length(magnitude.mag)
        filter3(cnt3) = 0;
    else
        filter3(cnt3) = func_CFAR(magnitude.mag(innerRange), magnitude.mag(innerRange(end)+1), cfarThreshold);
    end
end

if isempty(find(filter3))
    return
end

% Filter 4 : Acc magnitude CFAR
magnitude.acc = sum(filtfilt(b.acch, a.acch, acc.sample((wRange(1)-5):wRange(end), :)).^2, 2);

filter4 = filter3;
for cnt3 = find(filter4)'
    filter4(cnt3) = 0;
    outerRange = cnt3 + (-5:0);

    for cnt4 = outerRange
        innerRange = 100 + cnt4 + (-100:-1);

        % disp([num2str(cnt3),'_', num2str(cnt4)])
        if innerRange(1) >= 1 && func_CFAR(magnitude.acc(innerRange), magnitude.acc(innerRange(end) + 1), cfarThreshold)
            filter4(cnt3) = 1;
            break;
        end
    end
end

if isempty(find(filter4))
    return
end


filter5 = filter4;
for cnt = find(filter5)'
    innerRange = range(1) - 1 + cnt + (-5:5);

    if innerRange(1) < 1
        innerRange = 1:innerRange(end);
    end

    if innerRange(end) > t-1
        innerRange = innerRange(1):t-1;
    end

    c = corr(mag.dAngle(innerRange), mag.inferAngle(innerRange));
    filter5(cnt) = c > corrThreshold;
end

if isempty(find(filter5))
    return
end

result = true;
detectPoints = find(filter5)' + range(1) - 1;
end