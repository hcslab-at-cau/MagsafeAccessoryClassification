accId = 6;
showTrials = 10:10;
threshold = 45;

gt = struct();
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
    
    k = 1;
    for cnt2 = find(groundTruthFilter)'
        gt(k).(['value_', num2str(cnt)]) = cnt2;
        k = k+1;
    end
end


figure(9)
clf

nCol = length(showTrials);
nRow = 4;
disp(data(accId).name)


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
    

    subplot(nRow, nCol, nCol*2 + cnt)
    plot(detect)

    subplot(nRow, nCol, nCol*3 + cnt)
    plot(mag.inferAngle)

end