% Simple detection using diff
% diff is difference with Real magentometer and 
% infered magnetometer using gyroscope. 
% It can be use to environment where has no ferromagnetic.

for cnt = 1:length(data)
    for cnt2 = 1:nTrials
        detect = detected(cnt).trial(cnt2).filter6;
        f = data(cnt).name;
        % Attach -> diff  0 -> Other value   : +1
        % Detach -> diff  other value -> 0   : -1
        for cnt3 = find(detect)'
            beforeRange = (-50:-1) + cnt3;
            if beforeRange(1) <= 0
                beforeRange(1) = 1;
            end
            disp(beforeRange)
            disp('cnt3')
            disp(cnt3)
            disp(f)

            afterRange = (1:50) + cnt3;
            
            beforeData = abs(data(cnt).trial(cnt2).mag.sample(beforeRange, :));
            beforeMean = mean(beforeData(:));
            
            afterData = abs(data(cnt).trial(cnt2).mag.sample(afterRange, :));
            afterMean = mean(afterData(:));
            
            if afterMean > beforeMean
                disp('get')
                detect(cnt2) = -1;
            end
        end
        detected(cnt).trial(cnt2).filter6 = detect;
    end
end