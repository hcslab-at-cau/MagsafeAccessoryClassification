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
prefix.train = 'jaemin9_p2p';
prefix.test  = 'jaemin3_p2p';
nTrainCur = 50;

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);

chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};

[~, totalAcc] = func_make_feature_matrix(train, test, nTrainCur, strcmp(prefix.train, prefix.test));  % Just extract total accessory
otherAcc = totalAcc(~ismember(totalAcc, chargingAcc));

% Split train,test dataset
chargeTrain = train(ismember({train.name}, chargingAcc));
chargeTest = test(ismember({test.name}, chargingAcc));

otherTrain = train(ismember({train.name}, otherAcc));
otherTest = test(ismember({test.name}, otherAcc));

% Make feature matrix
[chargeFeatureMatrix, ~] = func_make_feature_matrix(chargeTrain, chargeTest, nTrainCur, strcmp(prefix.train, prefix.test));
[otherFeatureMatrix, ~] = func_make_feature_matrix(otherTrain, otherTest, nTrainCur, strcmp(prefix.train, prefix.test));

% Template init
template.knn = templateKNN('NumNeighbors', 11, 'Standardize',true);
template.svm = templateSVM('Standardize', false);
template.randomforest = templateTree('MaxNumSplits', 7);

% Train models
model(1).knn = fitcecoc(chargeFeatureMatrix.train.data, chargeFeatureMatrix.train.label, 'Learners', template.knn);
model(1).svm = fitcecoc(chargeFeatureMatrix.train.data, chargeFeatureMatrix.train.label, 'Learners', template.svm);
model(1).randomforest = fitcecoc(chargeFeatureMatrix.train.data, chargeFeatureMatrix.train.label, 'Learners', template.randomforest);

model(2).knn = fitcecoc(otherFeatureMatrix.train.data, otherFeatureMatrix.train.label, 'Learners', template.knn);
model(2).svm = fitcecoc(otherFeatureMatrix.train.data, otherFeatureMatrix.train.label, 'Learners', template.svm);
model(2).randomforest = fitcecoc(otherFeatureMatrix.train.data, otherFeatureMatrix.train.label, 'Learners', template.randomforest);

[pred(1).knn, prob(1).knn] = func_predict(model)


for cnt = 1:length(model)
    % Plot confusion matrix
    nRow = 2;
    nCol = 2;
    
    fig = figure('Name', ['train : ', prefix.train, '  test : ', prefix.test, num2str(cnt)], 'NumberTitle','off');
    fig.Position(1:4) = [200, 0, 1600, 1600]; 
    
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

end


return
%% Orientation labeling test