accId = 1;
trialId = 1;
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
status = false; % detach : false, attach : true
startPoint = -1; % start points where accessory was initially detected
refPoint = - 1; % reference point : detection points that has maximum value of magnitude
detectionPoints = []; 

interval = 100;
start = 100;
extractInterval = (-wSize:wSize);

[b.magh, a.magh] = butter(order, 10/rate * 2, 'high');
mag.dAngle = zeros(length(mag.sample), 1);

for t = 2:start
    mag.dAngle(t) = subspace(mag.sample(t, :)', mag.sample(t - 1, :)');
end

for t = 1 + start:300
    mag.dAngle(t) = subspace(mag.sample(t, :)', mag.sample(t - 1, :)');
    range = t + (-interval:-1);

    [flag, points] = func_detection(mag, gyro, acc, range, status);
    
    disp(t)

    if startPoint == -1 && flag
        startPoint = points(1);
        
    elseif flag
        detectionPoints = unique([detectionPoints,points]);
    end


    if startPoint ~= -1 && startPoint + interval <= t
        % select points & feature extractions
        magnitude = sum(filtfilt(b.magh, a.magh, mag.sample(startPoint:startPoint+interval, :)).^2, 2);
        refPoint = find(magnitude == max(magnitude(detectionPoints)), 1);

        extractRange = refPoint + extractInterval;
        
        [featureValue, inferredMag] = func_extract_feature(mag.sample, gyro.sample, extractRange, 1, rate);
        
        startPoint = -1;
        detectionPoints = [];
        
    end

    if refPoint ~= -1 && refPoint + chargingLatency <= t
        
    elseif refPoint ~= -1 && chargingStatus(t) == 1
        
    end

end


function [result, detectPoints] = func_detection(mag, gyro, acc, range, status)
result = false;
detectPoints = [];
interval = 100;

% Detection thresholds
magThreshold = 1;
cfarThreshold = .9999;
corrThreshold = .5;
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

magnitude.mag = sum(filtfilt(b.magh, a.magh, mag.sample(wRange, :)).^2, 2);

filter1 = magnitude.mag(wRange(end-99:end)) > magThreshold;
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
    innerRange = cnt3 + (-100:-1);
    
    filter3(cnt3) = func_CFAR(magnitude.mag(innerRange), magnitude.mag(cnt3), cfarThreshold);
end

if isempty(find(filter3))
    return
end

% Filter 4 : Acc magnitude CFAR
magnitude.acc = sum(filtfilt(b.acch, a.acch, acc.sample(wRange, :)).^2, 2);

filter4 = filter3;
for cnt3 = find(filter4)'
    filter4(cnt3) = 0;
    outerRange = cnt3 + (-5:0);

    for cnt4 = outerRange
        innerRange = interval + cnt4 + (-100:-1);

        if innerRange < 1
            innerRange = 1:innerRange(end);
        end

        if innerRange > length(range)
            innerRange = innerRange(1):length(range);
        end

        if(func_CFAR(acc.magnitude(innerRange), acc.magnitude(cnt4), cfarThreshold))
            filter4(cnt3) = 1;
            break;
        end
    end
end

if isempty(find(filter4))
    return
end

result = true;
detectPoints = find(filter4)';
end