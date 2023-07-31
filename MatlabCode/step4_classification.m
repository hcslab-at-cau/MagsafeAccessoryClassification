% Load data
if exist('featureName', 'var')
    disp('exist featureName')
    prefix.train = featureName;
    prefix.test  = featureName;
    nTrainCur = 25;
else
    % prefix.train = 'jaemin9_p2p_orient';
    prefix.train = 'jaemin6_p2p';
    prefix.test  = 'jaemin8_p2p';
    nTrainCur = 50;
end

chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};
chargingInfo = false;

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);


orientTrain = func_load_feature('jaemin');


% Table drop or include
% tableInfo = {'drop', 'griptok2'};
% tableInfo = [{'include'}, chargingAcc];
[featureMatrix, totalAcc] = func_make_feature_matrix(train, test, nTrainCur, strcmp(prefix.train, prefix.test));


% Template init
template.knn = templateKNN('NumNeighbors', 21, 'Standardize',false);
template.svm = templateSVM('Standardize', false);
template.randomforest = templateTree('MaxNumSplits', 7);


% Train models
[model.knn, predKNN, probKNN] = func_train_model(template.knn, featureMatrix, chargingAcc, chargingInfo);
[model.svm, predSVM, probSVM] = func_train_model(template.svm, featureMatrix, chargingAcc, chargingInfo);
[model.randomforest, predRandomForest, probRandomForest] = func_train_model(template.randomforest, featureMatrix, chargingAcc, chargingInfo);


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


if exist('featureName', 'var')
    clearvars featureName
end
