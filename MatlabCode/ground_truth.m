magThreshold = 30;
varThreshold = 1.0;
groundTruth = struct();

for cnt = 1:length(data)
    for cnt2 = 1:nTrials
        diffSum = data(cnt).trial(cnt2).mag.diffSum;
        filter = diffSum(1:length(diffSum)) > magThreshold;
            
        for cnt3 = find(filter)'
            range = cnt3 + (-5:5);
            if(var(diffSum(range)) > varThreshold)
                filter(cnt3) = 0;
            end
        end
        
        value = struct();
        value.attach = zeros(length(filter), 1);
        value.detach = zeros(length(filter), 1);    
        
        
        for cnt3 = find(filter)'
            if(filter(cnt3-1) == 1 && filter(cnt3+1) == 0)
                value.detach(cnt3) = -1;
            elseif(filter(cnt3-1) == 0 && filter(cnt3+1) == 1)
                value.attach(cnt3) = 1;
            end
        end

        for cnt3 = find(value.attach)'
            range = cnt3 + (1:wSize*2);

            for cnt4 = range
                value.attach(cnt4) = 0;
                value.detach(cnt4) = 0;
            end
        end

        for cnt3 = find(value.detach)'
            range = cnt3 + (1:wSize*2);

            for cnt4 = range
                value.attach(cnt4) = 0;
                value.detach(cnt4) = 0;
            end
        end
        value.filter = filter;
        value.attachCount = length(find(value.attach));
        value.detachCount = length(find(value.detach));
        
        groundTruth(cnt).trial(cnt2) = value;
    end
end

figure(25)
clf

accId = 1;
trials = 1:5;

nRows = 4;
nCols = length(trials);

for cnt = 1:length(trials)
    attach = groundTruth(accId).trial(trials(cnt)).attach;
    detach = groundTruth(accId).trial(trials(cnt)).detach;
    filter = groundTruth(accId).trial(trials(cnt)).filter;
    mag = data(accId).trial(trials(cnt)).mag;

    subplot(nRows, nCols, cnt)
    hold on
    plot(attach)
    plot(detach)
    legend({"attach", "detach"})
    title('attach & detach')

    subplot(nRows, nCols, nCols + cnt)
    plot(mag.diffSum)
    title('Diff sum')

    subplot(nRows, nCols, nCols*2 + cnt)
    plot(mag.diff)
    title('Diff')

    subplot(nRows, nCols, nCols*3 + cnt)
    plot(filter)
    title('filter')
end
