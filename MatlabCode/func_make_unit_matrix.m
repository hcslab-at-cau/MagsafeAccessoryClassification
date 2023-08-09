function [outputArg1,outputArg2] = func_make_unit_matrix(dataset)

nAcc = length(dataset);


lFeature = 3;
featureMatrix = [];
featureMatrix.train.data = zeros(nAcc * nTrainCur, lFeature);
featureMatrix.train.label = cell(nAcc * nTrainCur, 1);

featureMatrix.test.data = zeros(nAcc * nTestCur, lFeature);
featureMatrix.test.label = cell(nAcc * nTestCur, 1);

for cnt = 1:nAcc
    nTrains = length(train(cnt).feature);
    nTests = length(test(cnt).feature);
    nTrainIdx = false(1, nTrains);
    nTestIdx = false(1, nTests);

    cur = 
    
    if nTrains < nTrainCur
        nTrainIdx(randperm(nTrains, nTrains)) = true;
        curTrain = train(cnt).feature(nTrainIdx, :);
        diffIdx = length(abs(length(nTrainIdx) - nTrains));
        curTrain = [curTrain;  NaN(diffIdx,3,'single')];
    else
        nTrainIdx(randperm(nTrains, nTrainCur)) = true;
        curTrain = train(cnt).feature(nTrainIdx, :);
    end
    
    if nTests < nTestCur
        nTestIdx(randperm(nTests, nTests)) = true;
        curTest = test(cnt).feature(nTestIdx, :);
        diffIdx = length(abs(nTestCur- nTests));
        curTest = [curTest;  NaN(diffIdx,3,'single')];
    else
        nTestIdx(randperm(nTests, nTestCur)) = true;
        curTest = test(cnt).feature(nTestIdx, :);
    end

    range = (cnt - 1) * nTrainCur + (1:nTrainCur);
    featureMatrix.train.data(range, :) = [vertcat(curTrain)];   
    featureMatrix.train.label(range) = repmat({train(cnt).name}, nTrainCur, 1);

    range = (cnt - 1) * nTestCur + (1:nTestCur);
    featureMatrix.test.data(range, :) = [vertcat(curTest)];
    featureMatrix.test.label(range) = repmat({test(cnt).name}, nTestCur, 1); 
    
end


end

