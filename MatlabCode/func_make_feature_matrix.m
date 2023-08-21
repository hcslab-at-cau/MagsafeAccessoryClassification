function [featureMatrix, totalAcc]= func_make_feature_matrix(train, test, nTrainCur, isSame, tableInfo)
totalAcc = {train.name};

% Drop tables
if exist('tableInfo', 'var') && ~isempty(tableInfo)
    if strcmp(tableInfo(1), 'drop')
        train(ismember(totalAcc, tableInfo(2:end))) = [];
        test(ismember(totalAcc, tableInfo(2:end))) = [];
        totalAcc(ismember(totalAcc, tableInfo(2:end))) = [];

    elseif strcmp(tableInfo(1), 'include')
        train = train(ismember(totalAcc, tableInfo(2:end)));
        test = test(ismember(totalAcc, tableInfo(2:end)));
        totalAcc = totalAcc(ismember(totalAcc, tableInfo(2:end)));
    end
end

% Exclude accessory
if length(train) > length(test)
    train = train(ismember({train.name}, {test.name}));
    totalAcc = {train.name};
elseif length(train) < length(test)
    test = test(ismember({test.name}, {train.name}));
    totalAcc = {test.name};
end

nAcc = length(train);
nTrainTotal = length(train(1).feature);
nTestTotal = length(test(1).feature);

if isSame
    nTrainCur = min(nTrainTotal - 1, nTrainCur);
    nTestCur = nTrainTotal - nTrainCur;
else
    nTrainCur = min(nTrainTotal, nTrainCur);
    nTestCur = nTestTotal;
end

lFeature = 3;
featureMatrix = [];
featureMatrix.train.data = zeros(nAcc * nTrainCur, lFeature);
featureMatrix.train.label = cell(nAcc * nTrainCur, 1);

featureMatrix.test.data = zeros(nAcc * nTestCur, lFeature);
featureMatrix.test.label = cell(nAcc * nTestCur, 1);

for cnt = 1:nAcc
    nTrains = length(train(cnt).feature);
    nTests = length(test(cnt).feature);
    trainIdx = false(1, nTrains);
    testIdx = true(1, nTests);
    
    if nTrains < nTrainCur
        trainIdx(randperm(nTrains, nTrains)) = true;
        curTrain = train(cnt).feature(trainIdx, :);
        diffIdx = length(abs(length(trainIdx) - nTrains));
        curTrain = [curTrain;  NaN(diffIdx,3,'single')];

        curTrainLabel = [repmat({train(cnt).name}, nTrains, 1); repmat({'undefined'}, diffIdx, 1)];
    else
        trainIdx(randperm(nTrains, nTrainCur)) = true;
        curTrain = train(cnt).feature(trainIdx, :);
        curTrainLabel = repmat({train(cnt).name}, nTrainCur, 1);
    end
    
    if nTests < nTestCur
        curTest = test(cnt).feature(testIdx, :);
        diffIdx = length(abs(nTestCur- nTests));

        curTest = [curTest;  NaN(diffIdx,3,'single')];
        curTestLabel = [repmat({test(cnt).name}, nTests, 1); repmat({'undefined'}, diffIdx, 1)];
    else
        if isSame
            testIdx(trainIdx) = false;
        end

        curTest = test(cnt).feature(testIdx, :);
        curTestLabel = repmat({test(cnt).name}, length(find(testIdx)), 1);

        if length(find(testIdx)) < nTestCur
            diffIdx = length(abs(nTestCur- length(find(testIdx))));
            curTest = [curTest;  NaN(diffIdx,3,'single')];
            curTestLabel = [curTestLabel;repmat({'undefined'}, diffIdx, 1)];
        end        
    end

    range = (cnt - 1) * nTrainCur + (1:nTrainCur);
    featureMatrix.train.data(range, :) = [vertcat(curTrain)];   
    featureMatrix.train.label(range) = curTrainLabel;

    range = (cnt - 1) * nTestCur + (1:nTestCur);
    featureMatrix.test.data(range, :) = [vertcat(curTest)];
    featureMatrix.test.label(range) = curTestLabel;
end


% Flush NaN
kinds = {'train', 'test'};

for cnt = 1:length(kinds)
    kind = char(kinds(cnt));
    tmp = featureMatrix.(kind);
    
    k = tmp.data;
    k(any(isnan(k), 2), :) = [];
    tmp.data = k;

    tmp.label = tmp.label(~strcmp(tmp.label, 'undefined'));

    featureMatrix.(kind) = tmp;
end
end