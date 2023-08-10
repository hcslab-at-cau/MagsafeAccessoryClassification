dirs = {'jaemin3', 'jaemin4', 'jaemin6', 'jaemin7', 'jaemin8', 'jaemin9'...
    'insu1', 'junhyub1', 'Suhyeon1'};
mode = '_p2p';

% options = struct("Optimizer", "asha", "UseParallel", true, "ShowPlots", false, "Verbose", 0);
options = struct("UseParallel",true, "ShowPlots", false, "Verbose", 0);
chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};
mdlPath = '../MatlabCode/models/';

totalAccuracys = [];

for cnt = 1:length(dirs)
    trainDir = [char(dirs(cnt)), mode];
    testDirs = dirs(~ismember(dirs, dirs(cnt)));
    
    trainDataset = func_load_feature(trainDir);
    train = func_make_unit_matrix(trainDataset);

    mdl = fitcauto(train.data, train.label, "HyperparameterOptimizationOptions",options);
    totalAcc = unique(label);
    totalAcc{end + 1} = 'undefined';

    trainDir
    mdl

    % Save model
    save([mdlPath, trainDir, '.mat'], 'mdl');
    accuracys = [];

    for cnt2 = 1:length(testDirs)
        testDir = [char(dirs(cnt2)), mode];
        testDataset = func_load_feature(testDir);
        test = func_make_unit_matrix(testDataset);
        
        [preds, scores] = predict(mdl, test.data);
        probs = exp(scores) ./ sum(exp(scores),2);
        YPred = func_predict(test.label, preds, probs, totalAcc, chargingAcc);
        
        accuracy = sum(strcmp(YPred, test.label)) / length(test.label);
        accuracys(end + 1) = accuracy;
        % disp(['Accuracy: ', num2str(accuracy * 100),      
    end

    disp(['Accuracy: ', num2str(mean(accuracys) * 100), '%']);
    totalAccuracys(end + 1) = mean(accuracys) * 100;
end


% Plot accuracy
fig = figure('Name', 'Average accuracy', 'NumberTitle','off');
clf

bar(totalAccuracys)
ylim([80, 100])
grid on;
xticklabels(dirs);
title('attach accuracy')

%% 

featureName = 'jaemin9_p2p';

prefix.train = featureName;
prefix.test  = 'jaemin9_p2p';
nTrainCur = 25;

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);

[featureMatrix, totalAcc] = func_make_feature_matrix(train, test, nTrainCur, strcmp(prefix.train, prefix.test));

options = struct("Optimizer","asha","UseParallel",true);
mdl = fitcauto(featureMatrix.train.data, featureMatrix.train.label, "HyperparameterOptimizationOptions",options);

chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};
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

%% Split charging, non-charging model
