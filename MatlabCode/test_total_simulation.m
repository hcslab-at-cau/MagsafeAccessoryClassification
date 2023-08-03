tmp = data(accId).trial(trialId);
accName = data(accId).name;

chargingStatus = charging(accId).trial(trialId);
mag = tmp.mag;
gyro = tmp.gyro;
acc = tmp.acc;

chargingStatus = zeros(1, length(mag.sample));
if ~isempty(find(ismember(chargingAcc, accName))) % Not a charging status
    idx = find(ismember(chargingAcc, accName));
    chargingTime = charging(idx).trial(trialId).charging.sample;
    
    chargingStatus(chargingTime) = 1;
end

chargingLatency = 200;
status = false; % detach : false attach : true
sp = -1; % start points for feature extractions
rPoint = - 1; % reference point : detection points that has maximum value of magnitude
detectionPoints = []; 

interval = 100;
extractInterval = (-wSize:wSize);

[b.magh, a.magh] = butter(order, 10/rate * 2, 'high');


for t = 1 + start:length(mag.sample)
    range = t - 100;

    [flag, points] = func_detection(mag, gyro, acc, ~);
    
    if sp == -1 && flag
        sp = points(1);
    elseif flag
        detectionPoints = unique([detectionPoints,points]);
    end


    if sp + interval <= t
        % select points & feature extractions
        magnitude = sum(filtfilt(b.magh, a.magh, mag.sample(sp:sp+interval, :)).^2, 2);
        rPoint = find(magnitude == max(magnitude(detectionPoints)), 1);

        extractRange = rPoint + extractInterval;
        
        [featureValue, inferredMag] = func_extract_feature(mag.sample, gyro.sample, extractRange, 1, rate);
        
        sp = -1;
        detectionPoints = [];
    end

    if rPoint ~= -1 && rPoint + chargingLatency <= t
        
    elseif rPoint ~= -1 && chargingStatus(t) == 1
        
    end

end


function [result, detectPoints] = func_detection(mag, gyro, acc, range, status)
result = false;
detectPoints = [];

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
magnitude.mag = sum(filtfilt(b.magh, a.magh, mag.sample(range, :)).^2, 2);
filter1 = magnitude.mag > magThreshold;

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
    range = cnt3 + (-100:-1);
    filter3(cnt3) = func_CFAR(magnitude.mag(range), magnitude.mag(cnt3), cfarThreshold);
end

% Filter 4 : Acc magnitude CFAR
filter4 = filter3;
for cnt3 = find(filter4)'
    outerRange = cnt3 + (-5:0);

    for cnt4 = outerRange
        innerRange = cnt4 + (-100:-1);

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
end