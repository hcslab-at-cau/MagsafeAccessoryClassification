if ~newApp
    groundTruth = func_load_ground_truth(datasetName, folderName);
    interval = (-100:100);
else
    interval = (-200:50);
end
% Detection evaluation & Classifcation Accuracy filtered by detection
statistics = struct();

% Confusion matrix filtered by detection
labels.predict = [];
labels.label = [];
totalAcc = mdl.ClassNames;

for cnt = 1:length(results)
    tmp = struct();
    nTrials = length(results(cnt).trial);
    accName = results(cnt).name;
    statistics(cnt).name = accName;

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

                tmp(cnt2).trial(count).refPoint = detected(idx);
                tmp(cnt2).trial(count).clickPoint = t;
                tmp(cnt2).trial(count).pLabel = result(idx).pLabel;
                count = count + 1;
            end
        end

        % Detection accuracy
        attachNumber = length(find(~ismember({tmp(cnt2).trial.pLabel}, 'detach')));
        tmp(cnt2).attachCount = attachNumber;
        tmp(cnt2).detachCount = length(tmp(cnt2).trial) - attachNumber;
        tmp(cnt2).totalDetectionCount = length(trueDetection);
        tmp(cnt2).falsePositive = length(result) - length(tmp(cnt2).trial); 

        % Classification accuracy
        predictedLabels = {tmp(cnt2).trial.pLabel};
        predictedLabels(ismember(predictedLabels, 'detach')) = [];
        
        tmp(cnt2).trueLabelCount = length(find(ismember(predictedLabels, statistics(cnt).name)));
        tmp(cnt2).totalLabelCount = length(predictedLabels); 

        % For confusion matrix
        labels.predict = [labels.predict, predictedLabels];
        labels.label = [labels.label, repmat({accName}, 1, length(predictedLabels))];

    end

    statistics(cnt).result = tmp;
    statistics(cnt).attachAccuracy = sum(cell2mat({tmp.attachCount}))/sum(cell2mat({tmp.totalDetectionCount})/2) * 100;
    statistics(cnt).detachAccuracy = sum(cell2mat({tmp.detachCount}))/sum(cell2mat({tmp.totalDetectionCount})/2) * 100;
    statistics(cnt).falsePositive = sum(cell2mat({tmp.falsePositive}));

    statistics(cnt).classificationAccuracy = sum(cell2mat({tmp.trueLabelCount}))/sum(cell2mat({tmp.totalLabelCount})) * 100;
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

%% Show confusion matrix filtered by detection
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

calibrationIntreval = (-5*wSize:-2*wSize);
attachInterval = (-2*wSize:wSize);

for cnt = 1:length(data)
    cur = struct();
    classificationResult(cnt).name = data(cnt).name;

    for cnt2 = 1:length(data(cnt).trial)
        tmp = data(cnt).trial(cnt2);
        gyro = tmp.gyro;
        mag = tmp.mag;
        rmag=  tmp.rmag;

        if newApp
            click = data(cnt).trial(cnt2).detect.sample;
        else
            click = rmmissing(groundTruth.([accName, '_', num2str(cnt2)]));
        end

        for cnt3 = 1:length(click)
            t = click(cnt3);
            range = t + attachInterval;
            calRange = t + calibrationIntreval;

            [calm, bias, ~] = magcal(rmag.sample(calRange, :));
            
            if mod(cnt3, 2) == 1
                featureValue = func_extract_feature((rmag.sample(range, :)-bias)*calm, gyro.sample(range, :), 1:length(range), 4, 100);
            else
                featureValue = func_extract_feature_reverse((rmag.sample(range, :)-bias)*calm, gyro.sample(range, :), 1:length(range), 4, 100);
            end

            cur(cnt2).trial(cnt3).feature = featureValue;
            cur(cnt2).trial(cnt3).pred = predict(mdl, featureValue);
          
        end

    end
    classificationResult(cnt).result= cur;
end

