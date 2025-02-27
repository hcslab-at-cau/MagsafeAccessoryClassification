tic 

feature = struct();

for accId = 1:length(ori)
    nIdx = 1;
    feature(accId).name = ori(accId).name;
    feature(accId).feature = [];

    for cnt = 1:length(ori(accId).trial)
        cur = ori(accId).trial(cnt);
        rmag = cur.rmag;
        gyro = cur.gyro;
        detect = cur.detect.sample;
    
        % Quaternion
        % [gyro.q, gyro.cumQ] = func_quat_from_gyro(gyro.sample, 100);
        
        [calm, bias, ~] = magcal(rmag.sample(1:500, :));
        rmag.sample = (rmag.sample-bias)*calm;
        iter = 1:2:length(detect);
    
        for cnt2 = 1:length(iter)
            idx = detect(iter(cnt2));
            
            src = max(idx-200, 2);
            dst = min(idx+100, length(rmag.sample)-1);
            
            % Quaternion
            % rotated = quatrotate(quatinv(gyro.q(src, :)),  rmag.sample(src, :));
            % rotated = quatrotate(gyro.q(dst, :), rotated);
            % 
            % diff = rmag.sample(dst+1, :) - rotated;     
            % feature(accId).feature= [feature(accId).feature;diff];

            % Rotation Matrix
            refMag = rmag.sample(src-1, :);

            for cnt3 = src:dst
                euler = gyro.sample(cnt3, :) * 0.01;
                rotm = eul2rotm(euler, 'XYZ');

                refMag = (rotm\(refMag)')';
            end

            diff = rmag.sample(dst+1, :) - refMag;
            feature(accId).feature= [feature(accId).feature;diff];
        end
    end
end

toc

return;

%%
save(['./features/', 'ref2.mat'], 'feature')