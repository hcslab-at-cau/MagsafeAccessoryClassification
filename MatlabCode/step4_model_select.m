
featureName = 'jaemin9_p2p';

prefix.train = featureName;
prefix.test  = 'jaemin9_p2p';
nTrainCur = 25;

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);

[featureMatrix, totalAcc] = func_make_feature_matrix(train, test, nTrainCur, strcmp(prefix.train, prefix.test));

options = struct("Optimizer","asha","UseParallel",true);
mdl = fitcauto(featureMatrix.train.data, featureMatrix.train.label, "HyperparameterOptimizationOptions",options);

%%

[preds, scores] = predict(mdl,featureMatrix.test.data);
probs = exp(scores) ./ sum(exp(scores),2);
YPred = func_predict(featureMatrix.test.label, preds, probs, chargingAcc);


% Calculate the accuracy
accuracy = sum(strcmp(YPred, featureMatrix.test.label)) / length(featureMatrix.test.label);
disp(['Accuracy: ', num2str(accuracy * 100), '%']);


figure(22)
clf

c = confusionmat(featureMatrix.test.label, YPred, "Order", totalAcc);
cm = confusionchart(c, totalAcc);
cm.RowSummary = 'row-normalized';