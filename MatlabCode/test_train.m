clear;
dir = 'ref_p2p';

charger = {'batterypack1', 'charger1', 'charger2', 'charger3', ...
    'holder2', 'holder4'};
exclude = {'wallet3', 'holder3'};

template.linearSVM = templateSVM('Standardize', false, 'KernelFunction', 'linear', 'KernelScale', 1.0, ...
    'BoxConstraint', 1.0, 'SaveSupportVectors', true, 'Solver', 'SMO');

gamma = 0.001;

template.rbfSVM = templateSVM('Standardize', false, 'KernelFunction', 'rbf', 'KernelScale', 1/sqrt(gamma), ...
    'BoxConstraint', 1.0, 'SaveSupportVectors', true, 'Solver', 'SMO');

mdlPath = '../MatlabCode/models/';
dataset = func_load_feature(dir);

dataset = func_make_feature_matrix(dataset, dataset, 30, true);

train = dataset.train;
test = dataset.test;

idx = ismember(train.label, exclude);
train.data(idx, :) = [];
train.label(idx) = [];

idx = ismember(test.label, exclude);
test.data(idx, :) = [];
test.label(idx) = [];

mdl = fitcecoc(train.data, train.label, "Learners", template.('rbfSVM'));
[preds, scores] = predict(mdl, test.data);
probs= exp(scores) ./ sum(exp(scores),2);
preds = func_predict(test.label, preds, probs, mdl.ClassNames, charger);

accuracy = sum(strcmp(preds, test.label)) / length(test.label);
c = confusionmat(test.label, preds, "Order", mdl.ClassNames);
disp(['Accuracy: ', num2str(accuracy * 100), '%']);

cm = confusionchart(c, mdl.ClassNames);
sortClasses(cm, mdl.ClassNames)
cm.RowSummary = 'row-normalized';

%% Train unit dataset
kernelType = 'linearSVM';

dataset = func_load_feature(dir);
train = func_make_unit_matrix(dataset);

idx = ismember(train.label, exclude);
train.data(idx, :) = [];
train.label(idx) = [];

mdl = fitcecoc(train.data, train.label, "Learners", template.(kernelType));

save([mdlPath, 'ref_', kernelType, '.mat'], 'mdl');