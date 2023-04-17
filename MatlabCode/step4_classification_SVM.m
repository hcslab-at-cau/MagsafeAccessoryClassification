clear;

prefix.train = 'Test';
prefix.test = 'Test_nature2';

train = load([prefix.train, '.mat']);
test = load([prefix.test, '.mat']);

isSame = strcmp(prefix.train, prefix.test);

nAcc = length(train.data);
nTrainTotal = length(train.feature(1).trial);
nTestTotal = length(test.feature(1).trial);

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

lFeature = 4;
featureMatrix = [];
featureMatrix.train.data = zeros(nAcc * nTrainCur, lFeature);
featureMatrix.train.label = zeros(nAcc * nTrainCur, 1);

featureMatrix.test.data = zeros(nAcc * nTestCur, lFeature);
featureMatrix.test.label = zeros(nAcc * nTestCur, 1);

for cnt = 1:nAcc
    curTrain = train.feature(cnt).trial(trainIdx);
    curTest = test.feature(cnt).trial(testIdx);
    
    range = (cnt - 1) * nTrainCur + (1:nTrainCur);
    featureMatrix.train.data(range, :) = [vertcat(curTrain.diff), vertcat(curTrain.m)];   
    featureMatrix.train.label(range) = cnt;
        
    range = (cnt - 1) * nTestCur + (1:nTestCur);
    featureMatrix.test.data(range, :) = [vertcat(curTest.diff), vertcat(curTest.m)];
    featureMatrix.test.label(range) = cnt;   
end

result = [];
template.knn = templateKNN('NumNeighbors', 5, 'Standardize', true);

model.knn = fitcecoc(featureMatrix.train.data, featureMatrix.train.label, ...
    'Learners', template.knn);
model.svm = fitcecoc(featureMatrix.train.data, featureMatrix.train.label);

tmp = predict(model.knn, featureMatrix.test.data);
sum(tmp == featureMatrix.test.label) / length(featureMatrix.test.data)

tmp = predict(model.svm, featureMatrix.test.data);
sum(tmp == featureMatrix.test.label) / length(featureMatrix.test.data)