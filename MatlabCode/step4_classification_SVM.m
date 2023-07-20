clear;

% data load
prefix.train = 'value_p2p';
prefix.test = 'value_p2p';

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);

isSame = strcmp(prefix.train, prefix.test);

nAcc = length(train);
nTrainTotal = length(train(1).feature);
nTestTotal = length(test(1).feature);

nTrainCur = 15;
if isSame
    nTrainCur = min(nTrainTotal - 1, nTrainCur);
    nTestCur = nTrainTotal - nTrainCur;
else
    nTrainCur = min(nTrainTotal, nTrainCur);
    nTestCur = nTestTotal;
end

trainIdx = false(1, nTrainTotal);
trainIdx(randperm(nTrainTotal, nTrainCur)) = true;

testIdx = true(1, nTestTotal);
if isSame
    testIdx(trainIdx) = false;
end

lFeature = 3;
featureMatrix = [];
featureMatrix.train.data = zeros(nAcc * nTrainCur, lFeature);
featureMatrix.train.label = zeros(nAcc * nTrainCur, 1);

featureMatrix.test.data = zeros(nAcc * nTestCur, lFeature);
featureMatrix.test.label = zeros(nAcc * nTestCur, 1);

for cnt = 1:nAcc
    curTrain = train(cnt).feature(trainIdx, :);
    curTest = test(cnt).feature(testIdx, :);
    
    range = (cnt - 1) * nTrainCur + (1:nTrainCur);
    featureMatrix.train.data(range, :) = [vertcat(curTrain)];   
    featureMatrix.train.label(range) = cnt;
    
    range = (cnt - 1) * nTestCur + (1:nTestCur);
    featureMatrix.test.data(range, :) = [vertcat(curTest)];
    featureMatrix.test.label(range) = cnt;   
end

result = [];
template.knn = templateKNN('NumNeighbors', 5, 'Standardize', true);

model.knn = fitcecoc(featureMatrix.train.data, featureMatrix.train.label, ...
    'Learners', template.knn);
model.svm = fitcecoc(featureMatrix.train.data, featureMatrix.train.label);

tmp = predict(model.knn, featureMatrix.test.data);
s1 = sum(tmp == featureMatrix.test.label) / length(featureMatrix.test.data)

tmp2 = predict(model.svm, featureMatrix.test.data);
s2 = sum(tmp2 == featureMatrix.test.label) / length(featureMatrix.test.data)
%%

order = {};

for cnt = 1:length(train)
    order = [order; train(cnt).name];
end

figure(1)
clf
c = confusionmat(featureMatrix.test.label, tmp);
cm = confusionchart(c, order)


figure(2)
clf
c = confusionmat(featureMatrix.test.label, tmp2);
cm = confusionchart(c, order)
