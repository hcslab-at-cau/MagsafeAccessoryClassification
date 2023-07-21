clear;

prefix.train = 'jaemin8_p2p';
prefix.test = 'junhyub1_p2p';

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

k = 5;
[idx, distance] = knnsearch(featureMatrix.train.data, featureMatrix.test.data, ...
    'Distance', 'euclidean', 'k', k);
idx = featureMatrix.train.label(idx);

result = [];
result.count = zeros(length(idx), nAcc);
result.distance = zeros(length(idx), nAcc);
result.selected = zeros(length(idx), 1);
for cnt = 1:length(idx)
    for cnt2 = 1:k
        result.count(cnt, idx(cnt, cnt2)) = result.count(cnt, idx(cnt, cnt2)) + 1;
        result.distance(cnt, idx(cnt, cnt2)) = result.distance(cnt, idx(cnt, cnt2)) + distance(cnt, cnt2);
    end
    
    [mVal, mIdx] = max(result.count(cnt, :));
    if sum(result.count(cnt, :) == mVal) > 1
        mIdx = find(result.count(cnt, :) == mVal);
        
        [~, mIdx2] = sort(result.distance(cnt, mIdx), 'ascend');        
        mIdx = mIdx(mIdx2(1));
    end
    
    result.selected(cnt) = mIdx;    
end


result.acc = sum(result.selected == featureMatrix.test.label) / length(idx)

%%

