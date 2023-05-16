% Simple detection using diff
% diff is difference with Real magentometer and 
% infered magnetometer using gyroscope. 
% It can be use to environment where has no ferromagnetic.

for cnt = 1:length(data)
    data(cnt).attachCount = 0;
    data(cnt).detachCount = 0;
    for cnt2 = 1:nTrials
        detect = detected(cnt).trial(cnt2).filter6;
        f = data(cnt).name;
        % Attach -> diff  0 -> Other value   : +1
        % Detach -> diff  other value -> 0   : -1
        aCnt = 0;
        dCnt = 0;
        attach = struct();
        detach = struct();
        
        lCnt = 1;
        for cnt3 = find(detect)'
            beforeRange = (-100:-50) + cnt3;
            afterRange = (50:100) + cnt3;
            
            beforeData = abs(data(cnt).trial(cnt2).mag.diff(beforeRange, :));
            beforeMean = mean(beforeData(:));
            
            afterData = abs(data(cnt).trial(cnt2).mag.diff(afterRange, :));
            afterMean = mean(afterData(:));
            
            if afterMean > beforeMean
                % Attach
                aCnt = aCnt + 1;
            else
                % Detach
                dCnt = dCnt + 1;
            end
            % lCnt = lCnt + 1;
        end
        data(cnt).trial(cnt2).attach = aCnt;
        data(cnt).trial(cnt2).detach = dCnt;

        
        data(cnt).attachCount = data(cnt).attachCount + aCnt;
        data(cnt).detachCount = data(cnt).detachCount + dCnt;
    end

    data(cnt).attachAccurracy = data(cnt).attachCount/50 * 100.0;
    data(cnt).detachAccurracy = data(cnt).detachCount/50 * 100.0;
end

accuracy = zeros(length(data), 2);
acc = strings(1, length(data));

for cnt = 1:length(data)
    accuracy(cnt, 1) = data(cnt).attachAccurracy;
    accuracy(cnt, 2) = data(cnt).detachAccurracy;
    
    acc(cnt) = data(cnt).name;
end

figure(20)
clf
subplot(1, 2, 1)
bar(accuracy(:, 1))
ylim([0, 100])
grid on;
xticklabels(acc);
title('attach accuracy')

subplot(1, 2, 2)
bar(accuracy(:, 2))
ylim([0, 100])
grid on;
xticklabels(acc);
title('detach accuracy')