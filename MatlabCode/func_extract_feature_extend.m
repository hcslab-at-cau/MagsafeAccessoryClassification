function [diff, extractedRange] = func_extract_feature_extend(mag, gyro, range)
% Input mag is calibrated magnetometer values using magcal
% First get the hpf, lpf
rate = 100;


[b.low, a.low] = butter(4, 5/rate * 2, 'low');
[b.high, a.high] = butter(4, 10/rate * 2, 'high');

diff1s = zeros(length(range), 3);

for cnt = 2:length(range)
    t = range(cnt);

    euler = gyro.sample(t, :) * 1/100;
    rotm = eul2rotm(euler, 'XYZ');  
    diff1s(cnt, :) = mag(t, :) - (rotm\(mag(t-1,:))')';
end

diffSum = sqrt(sum(diff1s.^2, 2));

fh = filtfilt(b.high, a.high, diffSum);
fl = filtfilt(b.low, a.low, diffSum);


% figure(12312)
% clf
% 
% plot(fl)


hpfMaxIdx = find(max(fh)==fh);
hpfMaxIdxGlobal = range(1) + hpfMaxIdx - 1;
x = hpfMaxIdxGlobal - range(1) + 1;

tmp = fl((hpfMaxIdx-20):(hpfMaxIdx+20));
lpfMaxIdx = hpfMaxIdx - 20 -1 + find((max(tmp) == tmp));

filter = fl < 2;
front = find(filter(1:x-1));

sp = length(front);
interval = (-10:-1);

while sp > 1
    wIdx = front(sp);
    wRange = wIdx + interval;

    if wRange(1) < 1
        wRange = 1:wRange(end);
    end

    if length(find(fl(wRange) > fl(wIdx))) > 5
        if sp > 1
            sp = sp -1;
        else
            break;
        end
    else
        break;
    end
end

if sp > 5
    sp = front(sp-5);
else
    sp = front(sp);
end

ep = find(filter(x+1:end));
ep = x + ep(1);

extractedRange = range(1) - 1 + (sp:ep);

refMag = mag(extractedRange(1), :);

for cnt = 2:length(extractedRange)
    t = extractedRange(cnt);

    euler = gyro.sample(t, :) * 1/100;
    rotm = eul2rotm(euler, 'XYZ');  
    refMag = (rotm\(refMag)')';
end

diff = refMag;
end