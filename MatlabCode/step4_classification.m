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
    prefix.test  = 'jaemin4_p2p';
    nTrainCur = 50;
end

chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};
chargingInfo = true;

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
    [pred.(modelName), prob.(modelName)] = func_predict(model.(modelName), featureMatrix.test, chargingAcc, true);
end

fig = figure('Name', ['train : ', prefix.train, '  test : ', prefix.test], 'NumberTitle','off');
fig.Position(1:4) = [200, 0, 1600, 1600]; 

nRow = 2;
nCol = 2;

accuracys = [];
for cnt2 = 1:length(models)
    modelName = char(models(cnt2));

    s = sum(strcmp(pred.(modelName), featureMatrix.test.label)) / length(featureMatrix.test.label);
    accuracys = [accuracys;s];

    subplot(nRow, nCol, cnt2); 
    c = confusionmat(featureMatrix.test.label, pred.(modelName), "Order", totalAcc);
    cm = confusionchart(c, totalAcc);

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

return
%% Orientation labeling test