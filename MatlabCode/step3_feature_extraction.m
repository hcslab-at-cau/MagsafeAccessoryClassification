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
        if sum(detected(cnt).trial(cnt2).filter5) > 0
            cur = struct();

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
    
            feature(cnt).trial(cnt2) = cur;
        end
    end
    
    % Store the summary of the feature extraction result;
    nTrials = length([feature(cnt).trial(:).diff]) / 3;
    if nTrials > 1
        feature(cnt).summary = mean(reshape([feature(cnt).trial(:).diff], 3, nTrials), 2)';
        feature(cnt).summary(4:6) = std(reshape([feature(cnt).trial(:).diff], 3, nTrials)');
    else
        feature(cnt).summary = reshape([feature(cnt).trial(:).diff], 3, nTrials)';
        feature(cnt).summary(4:6) = [0, 0, 0];
    end

    disp(data(cnt).name)
    disp(feature(cnt).summary)
end


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