detectionGroundTruth = struct();
groundTruth = func_load_ground_truth(datasetName, folderName);
wRange = (-100:100);

for cnt = 1:length(data)
    accName = data(cnt).name;
    cur = struct();
    detectionGroundTruth(cnt).name = accName;
    nTrials = length(data(cnt).trial);

    for cnt2 = 1:nTrials
        detectTimes = rmmissing(groundTruth.([accName, '_', num2str(cnt2)]));
        attachCnt = 0;
        detachCnt = 0;    
        totalDetection = length(find(detected(cnt).trial(cnt2).filter6));
        maxLength = length(detected(cnt).trial(cnt2).filter6);
        fpCount = 0;

        for t = 1:length(detectTimes)
            detectGroundTruth = detectTimes(t);
            range = detectGroundTruth + wRange;

            if range(end) > maxLength
                range = range(1):maxLength;
            end
            
            if max(detected(cnt).trial(cnt2).filter6(range)) == 1 % detect occured in both estimated and ground-truth   
                if mod(t,2) == 1 % attach
                    attachCnt = attachCnt + 1;
                else  % detach
                    detachCnt = detachCnt + 1;
                end
            end

            if length(find(detected(cnt).trial(cnt2).filter6(range)')) > 1
                fpCount = fpCount + length(find(detected(cnt).trial(cnt2).filter6(range)'))-1;
            end
        end
        cur.trial(cnt2).attachCount = attachCnt;
        cur.trial(cnt2).detachCount = detachCnt;
        cur.trial(cnt2).falsePositive = totalDetection - attachCnt - detachCnt + fpCount;
    end

    detectionGroundTruth(cnt).value = cur;
    detectionGroundTruth(cnt).attach = sum([cur.trial.attachCount], 2);
    detectionGroundTruth(cnt).detach = sum([cur.trial.detachCount], 2);
    detectionGroundTruth(cnt).fp = sum([cur.trial.falsePositive], 2);
end