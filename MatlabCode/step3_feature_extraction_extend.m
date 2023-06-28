rotOrder = 'XYZ';

extractInterval = (-wSize:wSize);
feature = struct();
values = struct();

for cnt = 1:length(data)
    value = [];
    feature(cnt).name = data(cnt).name;
    values(cnt).name = data(cnt).name;
    nTrials = length(data(cnt).trial);
    k = 1;

    for cnt2 = 1:nTrials
        cur = struct();
        filter = detected(cnt).trial(cnt2).filter6;    
        mag = data(cnt).trial(cnt2).mag;
        gyro = data(cnt).trial(cnt2).gyro;
        filterIdx = find(filter);
        

        for cnt3 = 1:length(filterIdx)
            idx = filterIdx(cnt3);
            cur(cnt3).baseRange = idx;
            cur(cnt3).extractRange = cur(cnt3).baseRange + extractInterval;
            

            if cur(cnt3).extractRange(1) < 1
                cur(cnt3).extractRange = 1:cur(cnt3).extractRange(end);
            end

            if cur(cnt3).extractRange(end) > length(filter)
                cur(cnt3).extractRange = cur(cnt3).extractRange(1):length(filter);
            end

            cur(cnt3).euler = sum(gyro.sample(cur(cnt3).extractRange, :))* 1/rate;
            cur(cnt3).rotm = eul2rotm(cur(cnt3).euler, rotOrder);

            cur(cnt3).mags(1, :) = (cur(cnt3).rotm \ mag.sample(cur(cnt3).extractRange(1), :)')';
            cur(cnt3).mags(2, :) = mag.sample(cur(cnt3).extractRange(end), :);
            cur(cnt3).diff = cur(cnt3).mags(2, :) - cur(cnt3).mags(1, :);
            cur(cnt3).m = sqrt(sum(cur(cnt3).diff.^2));
            
            value = [value;cur(cnt3).diff];
            k = k + 1;
        end
        
        feature(cnt).trial(cnt2).cur = cur;
    end
    values(cnt).feature = value;
end