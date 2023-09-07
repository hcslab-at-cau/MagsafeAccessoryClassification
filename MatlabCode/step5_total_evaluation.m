if ~newApp
    groundTruth = func_load_ground_truth(datasetName, folderName);
    interval = (-100:100);
else
    interval = (-200:50);
end
% Detection evaluation & Classifcation Accuracy filtered by detection

statistics = struct();


for cnt = 1:length(results)
    cur = struct();
    nTrials = length(results(cnt).trial);
    statistics(cnt).name = results(cnt).name;

    for cnt2 = 1:nTrials
        result = results(cnt).trial(cnt2).result;

        if newApp
            trueDetection = data(cnt).trial(cnt2).detect.sample;
        else
            trueDetection = rmmissing(groundTruth.([accName, '_', num2str(cnt2)]));
        end
        
        detected = cell2mat({result.detect});
        count = 1;

        for cnt3 = 1:length(trueDetection)
            t = trueDetection(cnt3);
            range = t + interval;
            
            % Detection
            if ~isempty(find(ismember(detected, range), 1))
                idx = find(ismember(detected, range));
                
                % Select closest index
                if length(idx) ~= 1
                    m = abs(t-idx(1));
                    selectedIdx = idx(1);

                    for k = 2:length(idx)
                        if abs(t-idx(k)) < m
                            m = abs(t-idx(k));
                            selectedIdx = idx(k);
                        end
                    end
                    idx = selectedIdx;
                end

                % If this point is unmatched with attach/detach
                if mod(cnt3, 2) == 1 && strcmp(result(idx).pLabel, 'detach') || mod(cnt3, 2) == 0 && ~strcmp(result(idx).pLabel, 'detach')
                    % True : Attach, Predicted : Detach || True : Detach Predicted : Attach
                    continue;                    
                end

                cur(cnt2).trial(count).refPoint = detected(idx);
                cur(cnt2).trial(count).clickPoint = t;
                cur(cnt2).trial(count).pLabel = result(idx).pLabel;
                count = count + 1;
            end
        end

        % Detection accuracy
        attachNumber = length(find(~ismember({cur(cnt2).trial.pLabel}, 'detach')));
        cur(cnt2).attachCount = attachNumber;
        cur(cnt2).detachCount = length(cur(cnt2).trial) - attachNumber;
        cur(cnt2).totalDetectionCount = length(trueDetection);
        cur(cnt2).falsePositive = length(result) - length(cur(cnt2).trial); 

        % Classification accuracy
        predictedLabels = {cur(cnt2).trial.pLabel};
        predictedLabels(ismember(predictedLabels, 'detach')) = [];
        
        cur(cnt2).trueLabelCount = length(find(ismember(predictedLabels, statistics(cnt).name)));
        cur(cnt2).totalLabelCount = length(predictedLabels); 
    end

    statistics(cnt).result = cur;
    statistics(cnt).attachAccuracy = sum(cell2mat({cur.attachCount}))/sum(cell2mat({cur.totalDetectionCount})/2) * 100;
    statistics(cnt).detachAccuracy = sum(cell2mat({cur.detachCount}))/sum(cell2mat({cur.totalDetectionCount})/2) * 100;
    statistics(cnt).falsePositive = sum(cell2mat({cur.falsePositive}));

    statistics(cnt).classificationAccuracy = sum(cell2mat({cur.trueLabelCount}))/sum(cell2mat({cur.totalLabelCount})) * 100;
end

%% Show Detection accuracy
truePositive = zeros(2, length(statistics));
accNames = {statistics.name};

truePositive(1, :) = cell2mat({statistics.attachAccuracy});
truePositive(2, :) = cell2mat({statistics.detachAccuracy});
falsePositive = cell2mat({statistics.falsePositive});

truePositive(1, end+1) = mean(truePositive(1, :));
truePositive(2, end) = mean(truePositive(2, :));
falsePositive(1, end+1) = sum(falsePositive);

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

return;
%% Show confusion matrix filtered by detection
% fix

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

%% Evaluation feature extraction using ground-truth
classificationResult = struct();

attachInterval = (-2*wSize:wSize);

for cnt = 1:length(data)
    cur = struct();
    classificationResult(cnt).name = data(cnt).name;

    for cnt2 = 1:length(data(cnt).trial)
        if newApp
            click = data(cnt).trial(cnt2).detect.sample;
        else
            click = rmmissing(groundTruth.([accName, '_', num2str(cnt2)]));
        end

        for cnt3 = click
            
        end
    end


end


accNames
