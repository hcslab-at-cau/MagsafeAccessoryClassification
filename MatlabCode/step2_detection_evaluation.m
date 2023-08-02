if newApp == false
detectionGroundTruth = struct();
groundTruth = func_load_ground_truth(datasetName, folderName);
wRange = (-100:100);

for cnt = 1:length(data)
    accName = data(cnt).name;
    cur = struct();
    detectionGroundTruth(cnt).name = accName;
    nTrials = length(data(cnt).trial);
    total = 0;

    for cnt2 = 1:nTrials
        detectTimes = rmmissing(groundTruth.([accName, '_', num2str(cnt2)]));
        attachCnt = 0;
        detachCnt = 0;    
        totalDetection = length(find(detected(cnt).trial(cnt2).filter6));
        total = total + length(detectTimes);
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

            % if length(find(detected(cnt).trial(cnt2).filter6(range)')) > 1
            %     fpCount = fpCount + length(find(detected(cnt).trial(cnt2).filter6(range)'))-1;
            % end
        end
        cur.trial(cnt2).attachCount = attachCnt;
        cur.trial(cnt2).detachCount = detachCnt;
        cur.trial(cnt2).falsePositive = totalDetection - attachCnt - detachCnt + fpCount;
    end
    
    detectionGroundTruth(cnt).total = total;
    detectionGroundTruth(cnt).value = cur;
    detectionGroundTruth(cnt).attach = sum([cur.trial.attachCount], 2);
    detectionGroundTruth(cnt).detach = sum([cur.trial.detachCount], 2);
    detectionGroundTruth(cnt).fp = sum([cur.trial.falsePositive], 2);
end
end

%% For New app ver

if newApp == true
detectionGroundTruth = struct();
wRange = (-200:50);

for cnt = 1:length(data)
    accName = data(cnt).name;
    cur = struct();
    detectionGroundTruth(cnt).name = accName;
    nTrials = length(data(cnt).trial);
    total = 0;

    for cnt2 = 1:nTrials
        tmp = data(cnt).trial(cnt2);
        detect = tmp.detect.sample;
        filter = detected(cnt).trial(cnt2).filter6;
        attachCnt = 0;
        detachCnt = 0;    
        totalDetection = length(find(filter));
        total = total + length(detect);

        for t = 1:length(detect)
            detectedTime = detect(t);
            range = detectedTime + wRange;

            if length(find(filter(range))) > 0
                if mod(t,2) == 1 % attach
                    attachCnt = attachCnt + 1;
                else  % detach
                    detachCnt = detachCnt + 1;
                end
            end

        end
        cur.trial(cnt2).attachCount = attachCnt;
        cur.trial(cnt2).detachCount = detachCnt;
        cur.trial(cnt2).falsePositive = totalDetection - attachCnt - detachCnt;

    end
    detectionGroundTruth(cnt).total = total;
    detectionGroundTruth(cnt).value = cur;
    detectionGroundTruth(cnt).attach = sum([cur.trial.attachCount], 2);
    detectionGroundTruth(cnt).detach = sum([cur.trial.detachCount], 2);
    detectionGroundTruth(cnt).fp = sum([cur.trial.falsePositive], 2);
end
end

%% Plot accuracy
truePositive = zeros(2, length(detectionGroundTruth)+1);
falsePositive = zeros(1, length(detectionGroundTruth)+1);
accNames = {detectionGroundTruth.name};

for cnt = 1:length(detectionGroundTruth)
    detect = detectionGroundTruth(cnt);
    truePositive(1, cnt) = detect.attach /(detect.total/2) * 100; % for attach
    truePositive(2, cnt) = detect.detach /(detect.total/2) * 100; % for detach

    falsePositive(cnt) = detect.fp;
end

truePositive(1, end) = mean(truePositive(1, 1:length(data)));
truePositive(2, end) = mean(truePositive(2, 1:length(data)));
falsePositive(1, end) = sum(falsePositive(1, 1:length(data)));
accNames = [accNames, 'mean'];

f = figure('Name', [folderName, '_accuracy']);
clf

f.Position(2:4) = [250, 360, 720]; 

nRows = 3;
nCols = 1;

subplot(nRows, nCols, 1);
bar(truePositive(1, :))
ylim([0, 100])
grid on;
xticklabels(accNames);
title('attach accuracy')

subplot(nRows, nCols, 2);
bar(truePositive(2, :))
ylim([0, 100])
grid on;
xticklabels(accNames);
title('detach accuracy')

subplot(nRows, nCols, 3);
bar(falsePositive)
ylim([0, 40])
grid on;
xticklabels(accNames);
title('False postive')






