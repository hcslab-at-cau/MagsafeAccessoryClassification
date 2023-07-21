accId = 11;
showTrials = 1:10;
threshold = 50;

gt = struct();
for cnt = 1:length(showTrials)
    tmp = data(accId).trial(showTrials(cnt));
    diff = tmp.mag.diff;
    mag = tmp.mag;


    groundTruthFilter = mag.inferAngle > 0.05;

    for cnt2 = find(groundTruthFilter)'
        range = cnt2 + (0:wSize*2);

        if range(end) >= length(groundTruthFilter)
            range = range(1):length(groundTruthFilter)-1;
        end
            
        if max(groundTruthFilter(1 + range)) == 1
            if (range(1) + find(max(mag.inferAngle(range)) == mag.inferAngle(range)) -1)~=cnt2
                groundTruthFilter(cnt2) = 0;
            else
                groundTruthFilter(1 + range) = 0;
            end
            
        end
    end


    if length(find(groundTruthFilter)) ~= 10
        disp(length(find(groundTruthFilter)))
        disp(showTrials(cnt))
    end

    k = 1;
    for cnt2 = find(groundTruthFilter)'
        gt(k).(['value_', num2str(showTrials(cnt))]) = cnt2;
        k = k+1;
    end
    

end


%%

figure(8)
clf

showTrials = 1:4;
% showTrials = 6:10;

nCol = length(showTrials);
nRow = 4;
disp(data(accId).name)


for cnt = 1:length(showTrials)
    detect = detected(accId).trial(showTrials(cnt)).filter6;
    mag = data(accId).trial(showTrials(cnt)).mag;
    gyro = data(accId).trial(showTrials(cnt)).gyro;
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