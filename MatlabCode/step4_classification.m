% Load data
if exist('featureName', 'var')
    disp('exist featureName')
    prefix.train = featureName;
    prefix.test  = featureName;
    nTrainCur = 25;
else
    prefix.train = 'jaemin9_p2p_orient';
    % prefix.train = 'jaemin9_p2p';
    prefix.test  = 'jaemin3_p2p';
    nTrainCur = 50;
end


chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);

% Table drop or include
% tableInfo = {'drop', 'griptok2'};
tableInfo = {};
% tableInfo = [{'include'}, chargingAcc];
[featureMatrix, totalAcc] = func_make_feature_matrix(train, test, nTrainCur, strcmp(prefix.train, prefix.test), tableInfo);


% Template init
template.knn = templateKNN('NumNeighbors', 21, 'Standardize',true);
template.svm = templateSVM('Standardize', false);


% Train models
[model.knn, predKNN, probKNN] = func_train_model(template.knn, featureMatrix, chargingAcc);
[model.svm, predSVM, probSVM] = func_train_model(template.svm, featureMatrix, chargingAcc);

% Accuracy of KNN
s1 = sum(strcmp(predKNN, featureMatrix.test.label)) / length(featureMatrix.test.label)

% Plot confusion matrix for KNN result
figKNN = figure('Name','KNN','NumberTitle','off');
figKNN.Position(1:4) = [1000, 200, 900, 600];

c = confusionmat(featureMatrix.test.label, predKNN, "Order", totalAcc);
cm = confusionchart(c, totalAcc);
cm.RowSummary = 'row-normalized';

% Plot confusion matrix for SVM result
s2 = sum(strcmp(predSVM, featureMatrix.test.label)) / length(featureMatrix.test.label)

figSVM = figure('Name','SVM','NumberTitle','off');
figSVM.Position(1:4) = [500, 200, 900, 600];

c = confusionmat(featureMatrix.test.label, predSVM, "Order", totalAcc);
cm = confusionchart(c, totalAcc);
cm.RowSummary = 'row-normalized';

if exist('featureName', 'var')
    clearvars featureName
end
