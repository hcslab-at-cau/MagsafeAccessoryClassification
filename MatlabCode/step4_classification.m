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
    prefix.test  = 'jaemin3_p2p';
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


% Template init
template.knn = templateKNN('NumNeighbors', 11, 'Standardize',true);
template.svm = templateSVM('Standardize', false);
template.randomforest = templateTree('MaxNumSplits', 7);


% Train models
[chargerModel.knn, predKNN, probKNN] = func_train_model(template.knn, featureMatrix, chargingAcc, chargingInfo);
[chargerModel.svm, predSVM, probSVM] = func_train_model(template.svm, featureMatrix, chargingAcc, chargingInfo);
[chargerModel.randomforest, predRandomForest, probRandomForest] = func_train_model(template.randomforest, featureMatrix, chargingAcc, chargingInfo);


% Plot confusion matrix
nRow = 2;
nCol = 2;

% Define a single figure
fig = figure('Name', ['train : ', prefix.train, '  test : ', prefix.test], 'NumberTitle','off');
fig.Position(1:4) = [200, 0, 1600, 1600];  % increase width to accommodate 3 subplots

% Accuracy of KNN
s1 = sum(strcmp(predKNN, featureMatrix.test.label)) / length(featureMatrix.test.label)

% Plot confusion matrix for KNN result
subplot(nRow, nCol, 1); 
c = confusionmat(featureMatrix.test.label, predKNN, "Order", totalAcc);
cm = confusionchart(c, totalAcc);
cm.RowSummary = 'row-normalized';
title('KNN');

% Accuracy of SVM
s2 = sum(strcmp(predSVM, featureMatrix.test.label)) / length(featureMatrix.test.label)

% Plot confusion matrix for SVM result
subplot(nRow, nCol, 2); 
c = confusionmat(featureMatrix.test.label, predSVM, "Order", totalAcc);
cm = confusionchart(c, totalAcc);
cm.RowSummary = 'row-normalized';
title('SVM');

% Accuracy of Random forest
s3 = sum(strcmp(predRandomForest, featureMatrix.test.label)) / length(featureMatrix.test.label)

% Plot confusion matrix for random forest result
subplot(nRow, nCol, 3); 
c = confusionmat(featureMatrix.test.label, predRandomForest, "Order", totalAcc);
cm = confusionchart(c, totalAcc);
cm.RowSummary = 'row-normalized';
title('Random Forest');

% view(model.randomforest.BinaryLearners{1}.Trained{1},'Mode','graph')
return
%% Split model to charging and non-charging
clear;

prefix.train = 'jaemin9_p2p';
prefix.test  = 'jaemin3_p2p';
nTrainCur = 50;

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);

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
models = {'knn', 'svm', 'randomforest'};


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

for cnt = 1:length(accessorys)
    figure(20 + cnt)
    clf

    for cnt2 = 1:length(models)
        modelName = char(models(cnt2));
        disp(modelName)

        % s = sum(strcmp(pred(cnt).(modelName), featureMatrix.test.label)) / length(featureMatrix.test.label)

        subplot(nRow, nCol, cnt2); 
        % c = confusionmat(featureMatrix.(accName).test.label, pred(cnt).(modelName), "Order", accessory.(char(accessorys(cnt))));
        c = confusionmat(featureMatrix.(accName).test.label, pred(cnt).(modelName));
        % cm = confusionchart(c, accessory.(char(accessorys(cnt))));
        cm = confusionchart(c);

        cm.RowSummary = 'row-normalized';
        title(modelName);
    end
end




return
%% Orientation labeling test