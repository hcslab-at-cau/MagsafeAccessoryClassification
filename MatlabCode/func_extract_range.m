function extractedRange = func_extract_range(mag, gyro, range, refPoint)
% Input mag is calibrated magnetometer values using magcal
% RefPoint : Maximum value of Magnetometer HPF

rate = 100;

[b.low, a.low] = butter(4, 5/rate * 2, 'low');
lpfThreshold = 0.5;

diff1s = zeros(length(range), 3);

for cnt = 2:length(range)
    t = range(cnt);

    euler = gyro.sample(t, :) * 1/rate;
 
    rotm = eul2rotm(euler, 'XYZ');  
    diff1s(cnt, :) = mag(t, :) - (rotm\(mag(t-1,:))')';
end


diffSum = sqrt(sum(diff1s.^2, 2));

fl = filtfilt(b.low, a.low, diffSum);

ref = refPoint - range(1) + 1;

filter = fl < lpfThreshold;
sp = find(filter(1:ref-1));
sp = sp(end);

ep = find(filter(ref+1:end));

if isempty(ep)
    ep = [0];
end

ep = ref + ep(1);

extractedRange = range(1) - 1 + (sp:ep);
end