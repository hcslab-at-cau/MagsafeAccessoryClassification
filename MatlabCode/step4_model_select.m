dirs = {'jaemin3', 'jaemin4', 'jaemin6', 'jaemin7', 'jaemin8', 'jaemin9'...
    'insu1', 'junhyub1', 'Suhyeon1'};
mode = '_p2p';

options = struct("Optimizer", "asha", "UseParallel", true, "ShowPlots", false, "Verbose", 0);
SVMOptions = struct("UseParallel",true, "ShowPlots", false, "Verbose", 0);
% options = struct("UseParallel",true, "ShowPlots", false, "Verbose", 0);
chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};

mdlPath = '../MatlabCode/models/';
%% Find SVM
totalAccuracys = [];
confusions = struct();

totalAcc = {'batterypack1', 'charger1', 'charger2', 'griptok1', 'griptok2', ...
    'wallet1', 'wallet2', 'wallet3', 'wallet4', 'holder2', 'holder3', 'holder4', 'holder5'};
excludeAcc = {'holder5'};
totalAcc = totalAcc(~ismember(totalAcc, excludeAcc));
totalAcc{end + 1} = 'undefined';

for cnt = 1:length(dirs)
    trainDir = [char(dirs(cnt)), mode];
    testDirs = dirs(~ismember(dirs, dirs(cnt)));
    
    trainDataset = func_load_feature(trainDir);
    train = func_make_unit_matrix(trainDataset);
    
    % Exclude accessorys
    idx = ismember(train.label, excludeAcc);
    
    if ~isempty(find(idx,1))
        train.label(idx)= [];
        train.data(idx, :)= [];
    end
    
    confusions(cnt).name = char(dirs(cnt));

    mdl = fitcecoc(train.data, train.label, 'OptimizeHyperparameters','auto', "HyperparameterOptimizationOptions", SVMOptions);

    trainDir
    mdl

    % Save model
    % save([mdlPath, trainDir, '.mat'], 'mdl');
    accuracys = [];

    for cnt2 = 1:length(testDirs)
        testDir = [char(dirs(cnt2)), mode];
        testDataset = func_load_feature(testDir);
        test = func_make_unit_matrix(testDataset);

        idx = ismember(test.label, excludeAcc);
    
        if ~isempty(find(idx,1))
            test.label(idx)= [];
            test.data(idx, :)= [];
        end
        
        [preds, scores] = predict(mdl, test.data);
        probs = exp(scores) ./ sum(exp(scores),2);
        YPred = func_predict(test.label, preds, probs, totalAcc, chargingAcc);

        c = confusionmat(test.label, YPred, "Order", totalAcc);
        
        confusions(cnt).trial(cnt2).c = c;

        accuracy = sum(strcmp(YPred, test.label)) / length(test.label);
        accuracys(end + 1) = accuracy;
        % disp(['Accuracy: ', num2str(accuracy * 100),      
    end

    confusions(cnt).accessory = totalAcc;
    disp(['Accuracy: ', num2str(mean(accuracys) * 100), '%']);
    totalAccuracys(end + 1) = mean(accuracys) * 100;
end

%%
% Plot accuracy
fig = figure('Name', 'Average accuracy', 'NumberTitle','off');
clf

bar(totalAccuracys)
ylim([80, 100])
grid on;
xticklabels(dirs);
title('average accuracy')


% Plot confusions
fig = figure('Name', 'Confusions', 'NumberTitle','off');
clf

nRow = 3;
nCol = 3;

for cnt = 1:length(confusions)
    accessory = confusions(cnt).accessory;
    c = zeros(length(accessory), length(accessory));
    
    for cnt2 = 1:length(confusions(cnt).trial)
        cs = confusions(cnt).trial(cnt2).c;
        c = c + cs;
    end
    
    subplot(nRow, nCol, cnt);
    cm = confusionchart(c, accessory);
    sortClasses(cm, accessory)
    cm.RowSummary = 'row-normalized';
    title([confusions(cnt).name, '_confusion matrix']); 

end

return;
%% Find best model of each dataset & evaluate with other dataset using fitcauto
totalAccuracys = [];

for cnt = 1:length(dirs)
    trainDir = [char(dirs(cnt)), mode];
    testDirs = dirs(~ismember(dirs, dirs(cnt)));
    
    trainDataset = func_load_feature(trainDir);
    train = func_make_unit_matrix(trainDataset);

    mdl = fitcauto(train.data, train.label, "HyperparameterOptimizationOptions",options);

    trainDir
    mdl

    % Save model
    % save([mdlPath, trainDir, '.mat'], 'mdl');
    accuracys = [];

    for cnt = 1:length(testDirs)
        testDir = [char(dirs(cnt)), mode];
        testDataset = func_load_feature(testDir);
        test = func_make_unit_matrix(testDataset);
        trainAcc = unique(test.label);
        trainAcc{end + 1} = 'undefined';
        
        [preds, scores] = predict(mdl, test.data);
        probs = exp(scores) ./ sum(exp(scores),2);
        YPred = func_predict(test.label, preds, probs, trainAcc, chargingAcc);
        
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
title('average accuracy')

%% 

featureName = 'jaemin9_p2p';

prefix.train = featureName;
prefix.test  = 'jaemin9_p2p';
nTrainCur = 25;

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);

[featureMatrix, trainAcc] = func_make_feature_matrix(train, test, nTrainCur, strcmp(prefix.train, prefix.test));

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

c = confusionmat(featureMatrix.test.label, YPred, "Order", trainAcc);
cm = confusionchart(c, trainAcc);
cm.RowSummary = 'row-normalized';

%% User accuracys
clearvars accuracys

trials = 10;

accuracys = struct();

for cnt = 1:trials
    disp(['Trial : ', num2str(cnt)])
    for cnt = 1:length(dirs)
        trainDir = [char(dirs(cnt)), mode];
    
        trainDataset = func_load_feature(trainDir);
        [featureMatrix, ~] = func_make_feature_matrix(trainDataset, trainDataset, 25, true);
        trainAcc = unique(featureMatrix.test.label);
    
        % mdl = fitcauto(train.data, train.label, "HyperparameterOptimizationOptions",options);
        mdl = fitcecoc(featureMatrix.train.data, featureMatrix.train.label, 'OptimizeHyperparameters','auto', "HyperparameterOptimizationOptions", SVMOptions);
        
    
        [preds, scores] = predict(mdl, featureMatrix.test.data);
        probs= exp(scores) ./ sum(exp(scores),2);
       
        preds = func_predict(featureMatrix.test.label, preds, probs, trainAcc, chargingAcc);
        % sum(strcmp(preds, featureMatrix.test.label)) / length(featureMatrix.test.label)
        accuracys(cnt).accuracy(cnt) = sum(strcmp(preds, featureMatrix.test.label)) / length(featureMatrix.test.label) * 100;
    
        % fig = figure('Name', ['Dataset : ', trainDir], 'NumberTitle','off');
        % 
        % 
        % c = confusionmat(featureMatrix.test.label, preds, "Order", trainAcc);
        % cm = confusionchart(c, trainAcc);
        % 
        % cm.RowSummary = 'row-normalized';
    end
end