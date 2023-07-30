function [featureMatrix, totalAcc]= func_make_feature_matrix(train, test, nTrainCur, isSame, tableInfo)
totalAcc = {train.name};

if nargin < 5
        tableInfo = {};  % Set default value (or whatever makes sense in your case)
end



% Drop tables
if ~isempty(tableInfo)
    if strcmp(tableInfo(1), 'drop')
        train(ismember(totalAcc, tableInfo(2:end))) = [];
        test(ismember(totalAcc, tableInfo(2:end))) = [];
        totalAcc(ismember(totalAcc, tableInfo(2:end))) = [];

        % for cnt = 2:length(tableInfo)
        %     train(contains(totalAcc, char(tableInfo(cnt)))) = [];
        %     test(contains(totalAcc, char(tableInfo(cnt)))) = [];
        % end
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

length(train)
length(test)
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

trainIdx = false(1, nTrainTotal);
trainIdx(randperm(nTrainTotal, nTrainCur)) = true;

testIdx = true(1, nTestTotal);
if isSame
    testIdx(trainIdx) = false;
end

lFeature = 3;
featureMatrix = [];
featureMatrix.train.data = zeros(nAcc * nTrainCur, lFeature);
featureMatrix.train.label = cell(nAcc * nTrainCur, 1);

featureMatrix.test.data = zeros(nAcc * nTestCur, lFeature);
featureMatrix.test.label = cell(nAcc * nTestCur, 1);

for cnt = 1:nAcc
    if length(trainIdx) ~= length(train(cnt).feature)
        curTrain = train(cnt).feature(trainIdx(1:length(train(cnt).feature)), :);
        diffIdx = length(abs(length(trainIdx) - length(train(cnt).feature)));
        curTrain = [curTrain;  NaN(diffIdx,3,'single')];
    else
        curTrain = train(cnt).feature(trainIdx, :);
    end

    if length(testIdx) ~= length(test(cnt).feature)
        curTest = test(cnt).feature(testIdx(1:length(test(cnt).feature)), :);
        for cnt2 = 1:length(abs(length(testIdx) - length(test(cnt).feature)))
            curTest = [curTest;  NaN(1,3,'single')];
        end
    else
        curTest = test(cnt).feature(testIdx, :);
    end

    
    range = (cnt - 1) * nTrainCur + (1:nTrainCur);
    featureMatrix.train.data(range, :) = [vertcat(curTrain)];   
    featureMatrix.train.label(range) = repmat({train(cnt).name}, nTrainCur, 1);
    
    range = (cnt - 1) * nTestCur + (1:nTestCur);
    featureMatrix.test.data(range, :) = [vertcat(curTest)];
    featureMatrix.test.label(range) = repmat({test(cnt).name}, nTestCur, 1); 
end
end

