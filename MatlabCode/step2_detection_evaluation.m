detectionGroundTruth = struct();
groundTruth = load_ground_truth(datasetName, folderName);
wRange = (-20:20);

for cnt = 1:length(data)
    accName = data(cnt).name;
    cur = struct();
    detectionGroundTruth(cnt).name = accName;

    for cnt2 = 1:nTrials
        detectTimes = groundTruth.([accName, '_', num2str(cnt2)]);
        attachCnt = 0;
        detachCnt = 0;    

        for t = 1:length(detectTimes)
            detectGroundTruth = detectTimes(t);
            range = detectGroundTruth + wRange;
            if range(1) < 1
                range = 1:range(end);
            end

            
            if max(detected(cnt).trial(cnt2).filter6(range)) == 1 % detect occured in both estimated and ground-truth   
                if mod(t,2) == 1 % attach
                    attachCnt = attachCnt + 1;
                else  % detach
                    detachCnt = detachCnt + 1;
                end
            end

            cur.trial(cnt2).attachCount = attachCnt;
            cur.trial(cnt2).detachCount = detachCnt;
        end
    end

    detectionGroundTruth(cnt).value = cur;
    detectionGroundTruth(cnt).attach = sum([cur.trial.attachCount], 2);
    detectionGroundTruth(cnt).detach = sum([cur.trial.detachCount], 2);
end
