tmp = data(accId).trial(trialId);
mag = tmp.mag;

% 
chargnigLatency = 200;
accStatus = false;
detectPoints = -1;
start = 50;
detects = [];


for t = 1 + start:length(mag.sample)
    



end


function result = func_detection(mag, gyro, acc, range)
result = false;

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
magnitude = sum(filtfilt(b.magh, a.magh, mag.sample(range, :)).^2, 2);
filter1 = magnitude > magThreshold;

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
    filter3(cnt3) = func_CFAR(mag.magnitude(range), ...
        mag.magnitude(cnt3), cfarThreshold);
end

% Filter 4 : Acc magnitude CFAR
filter4 = filter3;
for cnt3 = find(filter4)'
    wRange = cnt3 + (-5:5);

    for cnt4 = range
        if(func_CFAR(acc.magnitude(wRange), acc.magnitude(wRange), cfarThreshold))
            filter(cnt3) = 1;
            break;
        end
    end
end


result = true;
end