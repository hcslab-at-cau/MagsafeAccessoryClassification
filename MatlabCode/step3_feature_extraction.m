rotOrder = 'XYZ';

feature = struct();
for cnt = 1:length(data)
    nTrials = length(data(cnt).trial);
    for cnt2 = 1:nTrials
        mag = data(cnt).trial(cnt2).mag;
        gyro = data(cnt).trial(cnt2).gyro;

        if sum(detected(cnt).trial(cnt2).filter5) > 0
            cur = struct();
            cur.baseIdx = find(detected(cnt).trial(cnt2).filter5, 1, 'last');
            cur.extractRange = cur.baseIdx + (-wSize/2:wSize / 2);
            cur.euler = sum(gyro.sample(cur.extractRange, :)) * 1/rate;
            cur.rotm = eul2rotm(cur.euler, rotOrder);
    
            cur.mags(1, :) = (cur.rotm \ mag.sample(cur.extractRange(1), :)')';
            cur.mags(2, :) = mag.sample(cur.extractRange(end), :);
            cur.diff = cur.mags(1, :) - cur.mags(2, :);
    
            feature(cnt).trial(cnt2) = cur;
        end
    end
end


figure(3)
clf
accId = 1;
trialId = 5;

hold on
mag = data(accId).trial(trialId).mag;
gyro = data(accId).trial(trialId).gyro;

cur = feature(accId).trial(trialId);

subplot 211
hold on
plot(mag.dAngle)
plot(gyro.dAngle)
xline([cur.extractRange(1), cur.extractRange(end)])

subplot 212
hold on
plot(mag.sample)
xline([cur.extractRange(1), cur.extractRange(end)])
