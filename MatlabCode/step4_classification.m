% clear;
% Load data
if exist('featureName', 'var')
    disp('exist featureName')
    prefix.train = featureName;
    prefix.test  = featureName;
    nTrainCur = 25;
    clearvars featureName
else
    % prefix.train = 'jaemin9_p2p_orient';
    prefix.train = 'jaemin9_p2p';
    prefix.test  = 'jaemin5_p2p';
    nTrainCur = 50;
end

chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};
chargingInfo = false;

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);

% Orientation test
% addTrain = func_load_feature('orientation_p2p');
% 
% for cnt = 1:length(addTrain)
%     idx = find(ismember({train.name}, addTrain(cnt).name));
%     train(idx) = addTrain(cnt);
% end


% Table drop or include
% tableInfo = {'drop', 'griptok2'};
% tableInfo = [{'include'}, chargingAcc];
[featureMatrix, totalAcc] = func_make_feature_matrix(train, test, nTrainCur, strcmp(prefix.train, prefix.test));

% totalAcc{end + 1} = 'non';

% Template init
template.knn = templateKNN('NumNeighbors', 11, 'Standardize',true);
template.svm = templateSVM('Standardize', false);
template.randomforest = templateTree('MaxNumSplits', 7);
models = fieldnames(template);


% Train & predict
for cnt2 = 1:length(models)
    modelName = char(models(cnt2));
  
    model.(modelName) = fitcecoc(featureMatrix.train.data, featureMatrix.train.label, 'Learners', template.(modelName));
    [pred.(modelName), scores] = predict(model.(modelName), featureMatrix.test.data);
    prob.(modelName) = exp(scores) ./ sum(exp(scores),2);
    totalAcc = unique(featureMatrix.test.label);

    % pred.(modelName) = func_predict(featureMatrix.test.label, pred.(modelName), prob.(modelName), totalAcc, chargingAcc);
end

fig = figure('Name', ['train : ', prefix.train, '  test : ', prefix.test], 'NumberTitle','off');
fig.Position(1:4) = [200, 0, 1600, 1600]; 

nRow = 2;
nCol = 2;

accuracys = [];
for cnt2 = 1:length(models)
    modelName = char(models(cnt2));

    s = sum(strcmp(pred.(modelName), featureMatrix.test.label)) / length(featureMatrix.test.label)
    accuracys = [accuracys;s];
    % totalAcc = unique(pred.(modelName));
    totalAcc = unique(featureMatrix.test.label);
    
    if ~isempty(find(ismember(totalAcc, 'undefined'), 1))
        totalAcc = totalAcc(~strcmp(totalAcc, 'undefined'));
    end
    totalAcc{end + 1} = 'undefined';

    subplot(nRow, nCol, cnt2); 
    c = confusionmat(featureMatrix.test.label, pred.(modelName), "Order", totalAcc);
    cm = confusionchart(c, totalAcc);

    sortClasses(cm, totalAcc)
    cm.RowSummary = 'row-normalized';   
    title(modelName);
end

mean(accuracys)
return;
%% Split model to charging and non-charging

% prefix.train = 'jaemin9_p2p';
% prefix.test  = 'jaemin4_p2p';
% nTrainCur = 50;

% train = func_load_feature(prefix.train);
% test = func_load_feature(prefix.test);

accessory.charging = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};

[~, totalAcc] = func_make_feature_matrix(train, test, nTrainCur, strcmp(prefix.train, prefix.test));  % Just extract total accessory
accessory.other = totalAcc(~ismember(totalAcc, accessory.charging));
accessorys = {'charging', 'other'};

% Split train,test dataset
chargeTrain = train(ismember({train.name}, accessory.charging));
chargeTest = test(ismember({test.name}, accessory.charging));

otherTrain = train(ismember({train.name}, accessory.other));
otherTest = test(ismember({test.name}, accessory.other));

% Make feature matrix
[featureMatrix.charging, ~] = func_make_feature_matrix(chargeTrain, chargeTest, nTrainCur, strcmp(prefix.train, prefix.test));
[featureMatrix.other, ~] = func_make_feature_matrix(otherTrain, otherTest, nTrainCur, strcmp(prefix.train, prefix.test));

% Template init
template.knn = templateKNN('NumNeighbors', 11, 'Standardize',true);
template.svm = templateSVM('Standardize', false);
template.randomforest = templateTree('MaxNumSplits', 7);

models = fieldnames(template);

% Train & predict
for cnt = 1:length(accessorys)
    accName = char(accessorys(cnt));

    for cnt2 = 1:length(models)
        modelName = char(models(cnt2));

        model(cnt).(modelName) = fitcecoc(featureMatrix.(accName).train.data, featureMatrix.(accName).train.label, 'Learners', template.(modelName));
        [pred(cnt).(modelName), prob(cnt).(modelName)] = func_predict(model(cnt).(modelName), featureMatrix.(accName).test, accessory.charging, false);
    end
end

nRow = 2;
nCol = 2;

accuracys = [];

% Plot confusion matrix
for cnt = 1:length(accessorys)
    accName = char(accessorys(cnt));
    figure('Name', [accName, '_confusion matrix'])
    clf

    for cnt2 = 1:length(models)
        modelName = char(models(cnt2));

        s = sum(strcmp(pred(cnt).(modelName), featureMatrix.(accName).test.label)) / length(featureMatrix.(accName).test.label);
        accuracys = [accuracys;s];

        subplot(nRow, nCol, cnt2); 
        c = confusionmat(featureMatrix.(accName).test.label, pred(cnt).(modelName), "Order", accessory.(accName));
        cm = confusionchart(c, accessory.(accName));

        cm.RowSummary = 'row-normalized';
        title(modelName);
    end
end


mean(accuracys)

%% Orientation labeling test
testLabels = featureMatrix.test.label;
totalAcc = unique(testLabels);
selectModel = 'svm';

probs = [];
preds = {};

for cnt = 1:length(pred.(selectModel))
    result = char(pred.(selectModel)(cnt));
    idx = find(ismember(totalAcc, result), 1);
    label= char(testLabels(cnt));

    if strcmp(result, label)
        probs(end + 1) = prob.(selectModel)(cnt, idx);
        preds(end + 1) = pred.(selectModel)(cnt);
    end
end

k = mean(probs)
% k = 0.17
lValue = length(find(probs < k))
gValue = length(find(probs >= k))
length(probs)


lIdx = find(probs < k);
badPreds = preds(lIdx);
badProbs = probs(lIdx);
bad = struct();

for cnt = 1:length(totalAcc)
    bad.(char(totalAcc(cnt))) = length(find(ismember(badPreds, totalAcc(cnt))));
end
bad

mean(badProbs)