function [diff, extractedRange] = func_extract_feature_extend(mag, gyro, range, refPoint)
% Input mag is calibrated magnetometer values using magcal
% RefPoint : Maximum value of Magnetometer HPF

rate = 100;

[b.low, a.low] = butter(4, 5/rate * 2, 'low');

diff1s = zeros(length(range), 3);

for cnt = 2:length(range)
    t = range(cnt);

    euler = gyro.sample(t, :) * 1/rate;
    rotm = eul2rotm(euler, 'XYZ');  
    diff1s(cnt, :) = mag(t, :) - (rotm\(mag(t-1,:))')';
end

diffSum = sqrt(sum(diff1s.^2, 2));

fl = filtfilt(b.low, a.low, diffSum);

hpfMaxIdx = refPoint - range(1) + 1;

if hpfMaxIdx -20 < 1
    startPoint = 1;
else
    startPoint = hpfMaxIdx - 20;
end

if hpfMaxIdx + 20 > length(fl)
    endPoint = length(fl);
else
    endPoint = hpfMaxIdx + 20;
end

tmp = fl(startPoint:endPoint);


lpfMaxIdx = hpfMaxIdx - 20 -1 + find((max(tmp) == tmp));

filter = fl < 1.0;
front = find(filter(1:hpfMaxIdx-1));

sp = length(front);
interval = (-20:-1);

% while sp > 1
%     wIdx = front(sp);
% 
%     wRange = wIdx + interval;
% 
%     if wRange(1) < 1
%         wRange = 1:wRange(end);
%     end
% 
%     if length(find(fl(wRange) > fl(wIdx))) > 10
%         sp = sp - 1;
%     else
%         break;
%     end
% end

% if sp > 5
%     sp = front(sp-5);
% else
%     sp = front(sp);
% end

sp = front(sp);

ep = find(filter(hpfMaxIdx+1:end));

if isempty(ep)
    ep = [0];
end
ep = hpfMaxIdx + ep(1);


extractedRange = range(1) - 1 + (sp:ep);

refMag = mag(extractedRange(1), :);


for cnt = 2:length(extractedRange)
    t = extractedRange(cnt);

    euler = gyro.sample(t, :) * 1/rate;
    rotm = eul2rotm(euler, 'XYZ');  
    refMag = (rotm\(refMag)')';
end

diff = mag(extractedRange(end), :) - refMag;
end