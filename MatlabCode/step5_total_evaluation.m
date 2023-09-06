% fix overall

if ~newApp
    groundTruth = func_load_ground_truth(datasetName, folderName);
    interval = (-100:100);
else
    interval = (-200:50);
end
statistics = struct();

for cnt = 1:length(results)
    cur = struct();
    accName = data(cnt).name;
    nTrials = length(results(cnt).trial);
    statistics(cnt).name = accName;
    total = 0;

    for cnt2 = 1:nTrials
        if results(cnt).trial(cnt2).detection == 0
            continue
        end
        result = results(cnt).trial(cnt2).result;

        if newApp
            detect = data(cnt).trial(cnt2).detect.sample;
        else
            detect = rmmissing(groundTruth.([accName, '_', num2str(cnt2)]));
        end
        
        attachCnt = 0;
        detachCnt = 0; 
        total = total + length(detect);

        detectedTime = cell2mat({result.detect});
        totalDetection = length(detectedTime);

        for t = 1:length(detect)
            clickedTime = detect(t);
            wRange = clickedTime + interval;

            if ~isempty(find(ismember(wRange, detectedTime), 1))
                idx = find(ismember(detectedTime, wRange));

                if length(idx) ~= 1
                    m = abs(clickedTime-idx(1));
                    selectedIdx = idx(1);

                    for k = 2:length(idx)
                        if abs(clickedTime-idx(k)) < m
                            m = abs(clickedTime-idx(k));
                            selectedIdx = idx(k);
                        end
                    end
                    idx = selectedIdx;
                end
                
                if strcmp(result(idx).pLabel, 'detach')
                    detachCnt = detachCnt + 1;
                else
                    attachCnt = attachCnt + 1;
                end
            end
        end

        cur.trial(cnt2).attachCount = attachCnt;
        cur.trial(cnt2).detachCount = detachCnt;
        cur.trial(cnt2).falsePositive = totalDetection - attachCnt - detachCnt; 
    end

    if total == 0
        statistics(cnt) = []; % fix
        continue;
    end

    statistics(cnt).total = total;
    statistics(cnt).detectionResult = cur;
    statistics(cnt).attach = sum([cur.trial.attachCount], 2);
    statistics(cnt).detach = sum([cur.trial.detachCount], 2);
    statistics(cnt).fp = sum([cur.trial.falsePositive], 2);
end
%%
for cnt = 1:length(statistics)
    cur = struct();
    accName = data(cnt).name;
    nTrials = length(results(cnt).trial);
    total = 0;

    for cnt2 = 1:nTrials
        if results(cnt).trial(cnt2).detection == 0
            continue
        end
        total = 1;

        if newApp
            detect = data(cnt).trial(cnt2).detect.sample;
        else
            detect = rmmissing(groundTruth.([accName, '_', num2str(cnt2)]));
        end

        result = results(cnt).trial(cnt2).result;
        totalAttach = 0;
        count = 0;
        
        for cnt3 = 1:length(result)
            refPoint = result(cnt3).detect;
            
            if isempty(find((detect - 200 < refPoint) & (detect+50 > refPoint), 1))
                trueLabel = 'undefined';  % false-positive
            else
                trueLabel = result(cnt3).label;
            end
     
            predictLabel = result(cnt3).pLabel;

            if strcmp(predictLabel, 'detach')
                continue;
            end

            if strcmp(trueLabel, predictLabel)
                count = count + 1;
            end
        end
        
        cur.trial(cnt2).correct = count;
        cur.trial(cnt2).totalAttach = length(detect) / 2;
    end

    
    if isempty(fieldnames(cur))
        cur.trial(1).correct = 0;
        cur.trial(1).totalAttach = 0;
    end

    statistics(cnt).classificationResult = cur;
    if isempty(statistics(cnt).attach) 
        statistics(cnt).classificationAccuracy = 0;
    elseif statistics(cnt).attach == 0
        statistics(cnt).classificationAccuracy = 0;
    else
        statistics(cnt).classificationAccuracy = sum([cur.trial.correct], 2)/statistics(cnt).attach * 100;
    end
    
end

%% Show Detection accuracy
truePositive = zeros(2, length(statistics)+1);
falsePositive = zeros(1, length(statistics)+1);
accNames = {statistics.name};

for cnt = 1:length(statistics)
    detect = statistics(cnt);
    
    if isempty(detect.total)
        truePositive(1, cnt) = 0; % for attach
        truePositive(2, cnt) = 0; % for detach
    
        falsePositive(cnt) = 0;
        continue
    end

    truePositive(1, cnt) = detect.attach /(detect.total/2) * 100; % for attach
    truePositive(2, cnt) = detect.detach /(detect.total/2) * 100; % for detach

    falsePositive(cnt) = detect.fp;
end

truePositive(1, end) = mean(truePositive(1, 1:length(statistics)));
truePositive(2, end) = mean(truePositive(2, 1:length(statistics)));
falsePositive(1, end) = sum(falsePositive(1, 1:length(statistics)));
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

%% Show classification accuracy
accuracys = cell2mat({statistics.classificationAccuracy});
accNames = {statistics.name};

f = figure('Name', [folderName, '_classification_accuracy']);
clf

nRows = 1;
nCols = 1;


f.Position(2:4) = [250, 720, 360]; 

accuracys(end + 1) = mean(accuracys);
accNames{end + 1} = 'mean';

subplot(nRows, nCols, 1);
bar(accuracys)
ylim([0, 100])
grid on;
xticklabels(accNames);
title('classification accuracy')
%% Show confusion matrix
labels.predict = [];
labels.label = [];
totalAcc = mdl.ClassNames;
% totalAcc{end + 1} = 'undefined';


for cnt = 1:length(results)
    accName = results(cnt).name;
    nTrials = length(results(cnt).trial);
    
    if isempty(find(ismember(totalAcc, accName), 1))
        continue;
    end
            
    for cnt2 = 1:nTrials
        result = results(cnt).trial(cnt2).result;

        if newApp
            click = data(cnt).trial(cnt2).detect.sample;
        else
            click = rmmissing(groundTruth.([accName, '_', num2str(cnt2)]));
        end
        
        if results(cnt).trial(cnt2).detection == 0
            continue
        end

        idx = true(length(result), 1);

        for cnt3 = 1:length(result)
            k = result(cnt3).detect;

            if isempty(find((click - 200 < k) & (click + 50 > k), 1)) || strcmp(result(cnt3).pLabel, 'detach') % false-positive
                idx(cnt3) = false;
            end
        end

        preds = {result.pLabel};
        predLabel = preds(idx);

        trues = {result.label};
        trueLabel = trues(idx);
        
        
        labels.predict = [labels.predict, predLabel];
        labels.label = [labels.label, repmat({accName}, 1, length(predLabel))];
    end
end

fig = figure('Name', 'confusion matrix', 'NumberTitle','off');
fig.Position(1:4) = [200, 0, 800, 800]; 

c = confusionmat(labels.label, labels.predict, "Order", totalAcc);
cm = confusionchart(c, totalAcc);
sortClasses(cm, totalAcc)
cm.RowSummary = 'row-normalized';
title('confusion matrix');

return;

%% Evaluation knnsearch 
distances = [];



values = cell2mat({results.count});
accNames = {distances.name};

f = figure('Name', 'Distance effects');
clf

nRows = 1;
nCols = 1;

f.Position(2:4) = [250, 720, 360]; 

% accuracys(end + 1) = mean(accuracys);
% accNames{end + 1} = 'mean';

subplot(nRows, nCols, 1);
bar(values)
ylim([0, 100])
grid on;
xticklabels(accNames);
title(['Distance filtering (%) threshold : ', num2str(distanceThreshold)])

return;
%%
if ~newApp
    groundTruth = func_load_ground_truth(datasetName, folderName);
    interval = (-100:100);
else
    interval = (-200:50);
end
detectAccuracy = struct();

for cnt = 1:length(results)
    cur = struct();
    accName = data(cnt).name;
    nTrials = length(results(cnt).trial);
    statistics(cnt).name = accName;
    total = 0;

    for cnt2 = 1:nTrials
        if results(cnt).trial(cnt2).detection == 0
            continue
        end
        result = results(cnt).trial(cnt2).result;

        if newApp
            detect = data(cnt).trial(cnt2).detect.sample;
        else
            detect = rmmissing(groundTruth.([accName, '_', num2str(cnt2)]));
        end
        
        attachCnt = 0;
        detachCnt = 0; 
        total = total + length(detect);

        detectedTime = cell2mat({result.detect});
        totalDetection = length(detectedTime);

        for t = 1:length(detect)
            clickedTime = detect(t);
            wRange = clickedTime + interval;

            if ~isempty(find(ismember(wRange, detectedTime), 1))
                idx = detectedTime()
                
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

    if total == 0
        detectAccuracy(cnt) = [];
        continue;
    end

    detectAccuracy(cnt).total = total;
    detectAccuracy(cnt).detectionResult = cur;
    detectAccuracy(cnt).attach = sum([cur.trial.attachCount], 2);
    detectAccuracy(cnt).detach = sum([cur.trial.detachCount], 2);
    detectAccuracy(cnt).fp = sum([cur.trial.falsePositive], 2);
end