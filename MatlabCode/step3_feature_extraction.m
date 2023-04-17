rotOrder = 'XYZ';

extractInterval = [-wSize / 2, wSize / 4];
feature = struct();
for cnt = 1:length(data)
    feature(cnt).name = data(cnt).name;    
    nTrials = length(data(cnt).trial);
    for cnt2 = 1:nTrials
        mag = data(cnt).trial(cnt2).mag;
        gyro = data(cnt).trial(cnt2).gyro;

        % If detected
        cur = struct();
        if sum(detected(cnt).trial(cnt2).filter5) > 0
            % Compute the range for feature extraction
            cur.baseRange(1) = find(detected(cnt).trial(cnt2).filter5, 1);
            cur.baseRange(2) = find(detected(cnt).trial(cnt2).filter5, 1, 'last');                      
            cur.extractRange = cur.baseRange + extractInterval;
           
            % Compute the rotation matrix from "after attachment" to "before attachment"
            cur.euler = sum(gyro.sample(cur.extractRange, :)) * 1/rate;
            cur.rotm = eul2rotm(cur.euler, rotOrder);
    
            % Rotate the (before) magnetometer reading and compare the readings
            cur.mags(1, :) = (cur.rotm \ mag.sample(cur.extractRange(1), :)')';
            cur.mags(2, :) = mag.sample(cur.extractRange(end), :);
            cur.diff = cur.mags(2, :) - cur.mags(1, :);
            cur.m = sqrt(sum(cur.diff.^2));            
        else
            cur.baseRange = [];
            cur.extractRange = [];
            cur.euler = [];
            cur.rotm = [];
            cur.mags = [];
            cur.diff = [0, 0, 0];
            cur.m = 0;
        end
        
        feature(cnt).trial(cnt2) = cur;
    end
    
    % Store the summary of the feature extraction result;
    tmp = reshape([feature(cnt).trial(:).diff], 3, nTrials)';
    for cnt2 = size(tmp, 1):-1:1
        if tmp(cnt2, :) == [0, 0, 0]
            tmp(cnt2, :) = [];
        end
    end

    feature(cnt).summary = mean(tmp);

    disp(data(cnt).name)
    disp(feature(cnt).summary)
end

save([path.postfix, '.mat'], 'data', 'detected', 'feature');

figure(3)
clf
accId = 11;
trialId = 1;


hold on
mag = data(accId).trial(trialId).mag;
gyro = data(accId).trial(trialId).gyro;

cur = feature(accId).trial(trialId);

subplot 211
hold on
plot(mag.dAngle)
plot(gyro.dAngle)
xline([cur.extractRange(1), cur.extractRange(end)])

subplot 223
hold on
plot(mag.sample)
xline([cur.extractRange(1), cur.extractRange(end)])

subplot 224
hold on
plot(gyro.sample)
xline([cur.extractRange(1), cur.extractRange(end)])