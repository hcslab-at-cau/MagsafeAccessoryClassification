accId = 7;
showTrials =8:8;
threshold = 70;

figure(9)
clf

nCol = length(showTrials);
nRow = 2;
disp(data(accId).name)


for cnt = 1:nTrials
    tmp = data(accId).trial(cnt);
    diff = tmp.mag.diff;
    diffMagnitude = zeros(1, length(diff(1, :)));
    count = 0;

    for cnt2 = 1:length(diffMagnitude)
        diffMagnitude = sqrt(sum(diff.^2, 2));
    end
    
    tmpFilter = diffMagnitude > threshold;
    groundTruthFilter = zeros(length(tmpFilter), 1);

    for cnt2 = 2:length(tmpFilter)
        if tmpFilter(cnt2-1) ~= tmpFilter(cnt2)
            groundTruthFilter(cnt2) = 1;
            count = count +1;
        end

    end
    if count ~= 10
        disp(cnt)
    end

    for cnt2 = find(groundTruthFilter)'
        
    end

    gt = find(groundTruthFilter);
end



for cnt = 1:length(showTrials)
    detect = detected(accId).trial(showTrials(cnt)).filter6;
    mag = data(accId).trial(showTrials(cnt)).mag;
    gyro = data(accId).trial(showTrials(cnt)).gyro;
    corrData = data(accId).trial(showTrials(cnt)).corr(1, :);
    diff = mag.diff;
    diffMagnitude = zeros(1, length(diff(1, :)));

    for cnt2 = 1:length(diffMagnitude)
        diffMagnitude = sqrt(sum(diff.^2, 2));
    end

    diffFilter = diffMagnitude > threshold;

    subplot(nRow, nCol, cnt)
    plot(diffMagnitude)

    subplot(nRow, nCol, nCol + cnt)
    plot(diffFilter)
    
end