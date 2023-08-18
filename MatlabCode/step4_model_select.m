dirs = {'jaemin3', 'jaemin4', 'jaemin6', 'jaemin7', 'jaemin8', 'jaemin9', 'insu1', 'junhyub1', 'Suhyeon1'};
userDirs = {'jaemin4', 'insu1', 'junhyub1', 'Suhyeon1'};

mode = '_p2p';

% options = struct("Optimizer", "asha", "UseParallel", true, "ShowPlots", false, "Verbose", 0);
SVMOptions = struct("UseParallel",true, "ShowPlots", false, "Verbose", 0);
options = struct("UseParallel",true, "ShowPlots", false, "Verbose", 0);
chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};

% template.svm = templateSVM('Standardize',true, 'KernelFunction','linear', 'OutlierFraction', 0.1, ...
%     'KernelScale', 2.0, 'Solver','ISDA');

template.svm = templateSVM('Standardize',true, 'KernelFunction','linear', 'KernelScale', 2.0);

mdlPath = '../MatlabCode/models/';
%% Evaluation of user to user
totalAccuracys = [];
confusions = struct();
models = struct();

% Use totalAcc rather than trainAcc, Because of accessory inconsistency in each dataset
totalAcc = {'batterypack1', 'charger1', 'charger2', 'griptok1', 'griptok2', ...
    'wallet1', 'wallet2', 'wallet3', 'wallet4', 'holder2', 'holder3', 'holder4', 'holder5'};
excludeAcc = {'holder3', 'holder5'};
totalAcc = totalAcc(~ismember(totalAcc, excludeAcc));
totalAcc{end + 1} = 'undefined';


for cnt = 1:length(userDirs)
    models(cnt).name = char(userDirs(cnt));

    testDir = [char(userDirs(cnt)), mode];
    trainDirs = userDirs(~ismember(userDirs, userDirs(cnt)));

    trainDataset = func_load_feature([char(trainDirs(1)), '_p2p']);
    train = func_make_unit_matrix(trainDataset);

    testDataset = func_load_feature(testDir);
    test = func_make_unit_matrix(testDataset);

    % Concat train dataset
    for cnt2 = 2:length(trainDirs)
        trainDataset = func_load_feature([char(trainDirs(cnt2)), '_p2p']);
        tmp = func_make_unit_matrix(trainDataset);
        
        train.label = [train.label;tmp.label];
        train.data = [train.data;tmp.data];
    end
    
    % Exclude unnessary accessories
    idx = ismember(train.label, excludeAcc);
    
    if ~isempty(find(idx,1))
        train.label(idx)= [];
        train.data(idx, :)= [];
    end
    
    confusions(cnt).name = char(userDirs(cnt));

    mdl = fitcecoc(train.data, train.label, "Learners", template.svm);

    disp(['test dir is ', testDir])
    models(cnt).model = mdl;

    % Save model
    % save([mdlPath, trainDir, '.mat'], 'mdl');
    
    idx = ismember(test.label, excludeAcc);

    if ~isempty(find(idx,1))
        test.label(idx)= [];
        test.data(idx, :)= [];
    end

    [preds, scores] = predict(mdl, test.data);
    probs = exp(scores) ./ sum(exp(scores),2);

    % Consider charging status
    preds = func_predict(test.label, preds, probs, totalAcc, chargingAcc);

    c = confusionmat(test.label, preds, "Order", totalAcc);
    confusions(cnt).trial(1).c = c;

    accuracy = sum(strcmp(preds, test.label)) / length(test.label);

    confusions(cnt).accessory = totalAcc;
    disp(['Accuracy: ', num2str(accuracy * 100), '%']);
    totalAccuracys(end + 1) = accuracy * 100;
end

plot_accuracy(totalAccuracys, confusions, userDirs, 'user to user');
return;
%% Train and test same user
trials = 1000;

totalAccuracys = [];
confusions = struct();

for cnt = 1:length(dirs)
    testDir = [char(dirs(cnt)), mode];
    trainDataset = func_load_feature(testDir);
    confusions(cnt).name = char(dirs(cnt));

    disp(['Trial dir_', testDir])
    accuracys = [];

    for cnt2 = 1:trials
        [featureMatrix, ~] = func_make_feature_matrix(trainDataset, trainDataset, 25, true);
        trainAcc = unique(featureMatrix.test.label);
        trainAcc{end + 1} = 'undefined';
    
        % mdl = fitcecoc(featureMatrix.train.data, featureMatrix.train.label, 'Learners', template.svm);
        
        mdl = fitcauto(featureMatrix.train.data, featureMatrix.train.label, "HyperparameterOptimizationOptions",options, ...
            "learners", "svm", "OptimizeHyperparameters","auto");
        
        [preds, scores] = predict(mdl, featureMatrix.test.data);
        probs= exp(scores) ./ sum(exp(scores),2);
        
        % Consider charing status
        preds = func_predict(featureMatrix.test.label, preds, probs, trainAcc, chargingAcc);
        accuracys(end + 1) = sum(strcmp(preds, featureMatrix.test.label)) / length(featureMatrix.test.label) * 100;

        c = confusionmat(featureMatrix.test.label, preds, "Order", trainAcc);
        confusions(cnt).trial(cnt2).c = c;
    end
    confusions(cnt).accessory = trainAcc;
    totalAccuracys(end + 1) = mean(accuracys);
end

plot_accuracy(totalAccuracys, confusions, dirs, 'PerUser')
%% Find best model of each dataset & evaluate with other dataset using fitcauto
totalAccuracys = [];

for cnt = 1:length(dirs)
    testDir = [char(dirs(cnt)), mode];
    trainDirs = dirs(~ismember(dirs, dirs(cnt)));
    
    trainDataset = func_load_feature(testDir);
    train = func_make_unit_matrix(trainDataset);

    mdl = fitcauto(train.data, train.label, "HyperparameterOptimizationOptions",options);

    testDir
    mdl

    % Save model
    % save([mdlPath, trainDir, '.mat'], 'mdl');
    accuracys = [];

    for cnt = 1:length(trainDirs)
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


%% Function for plotting

function [] = plot_accuracy(accuracy, confusions, xLabels, name)

if ~exist('name', 'var')
    name = '';
end

fig = figure('Name', [name, '_accuracy'], 'NumberTitle','off');
clf

bar(accuracy)
ylim([80, 100])
grid on;
xticklabels(xLabels);  
title('Accuracy')

% Plot confusions
fig = figure('Name', [name, '_Confusions matrix'], 'NumberTitle','off');
clf

n = ceil(sqrt(length(confusions)));

nRow = n;
nCol = n;

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
end