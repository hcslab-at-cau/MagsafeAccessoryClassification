function [model, pred, prob] = func_train_model(templateModel, train, test, nTrainCur, tableInfo)
chargingAcc = [1, 2, 3, 10, 11, 12];
totalAcc = {train.name};

if nargin < 5
        tableInfo = {};  % Set default value (or whatever makes sense in your case)
end

% Drop tables
if exist(tableInfo)
    if strcmp(tableInfo(1), 'drop')
        for cnt = 1:length(tableInfo)
            train(contains(totalAcc, char(tableInfo(cnt)))) = [];
            test(contains(totalAcc, char(tableInfo(cnt)))) = [];
        end
    elseif strcmp(tableInfo(1), 'include')
        train = train(ismember(totalAcc, includeTable));
        test = test(ismember(totalAcc, includeTable));
    end
end
    

isSame = strcmp(prefix.train, prefix.test);

nAcc = length(train);
nTrainTotal = length(train(1).feature);
nTestTotal = length(test(1).feature);

nTrainCur = 25;
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
    featureMatrix.train.label(range) = cnt;
    
    range = (cnt - 1) * nTestCur + (1:nTestCur);
    featureMatrix.test.data(range, :) = [vertcat(curTest)];
    featureMatrix.test.label(range) = cnt;   
end

% Training model
model = fitcecoc(featureMatrix.train.data, featureMatrix.train.label, 'Learners', templateModel);
[pred, scores] = predict(model, featureMatrix.test.data);

% Get probability of each label
prob = exp(scores) ./ sum(exp(scores),2);

% Consider charging status
pred = func_considerCharge(featureMatrix.test.label, pred, prob, totalAcc, chargingAcc);


    function result = func_load_charging_status(root, postfix)
    data = struct();
    
    prevCnt = 0;
    cIdx = 1;
    
    for cnt = 1:size(postfix, 1)
        path.root = root;
        path.postfix = deblank(postfix(cnt, :));
        path.data = [path.root '/', path.postfix, '/'];
        
        % Data path for each accessory
        disp(path.data)
        path.accessory = dir(path.data);
        path.accessory(~[path.accessory(:).isdir]) = [];
        path.accessory(ismember({path.accessory(:).name}, {'.', '..'})) = [];
    
        for cnt2 = prevCnt + (1:length(path.accessory))
            files = dir([path.data, path.accessory(cnt2-prevCnt).name, '/**/*.csv']);
    
            if isempty(find(contains({files(:).name}, 'Charging'), 1))
                disp(path.accessory(cnt2-prevCnt).name)
                continue
            end
            
    
            data(cIdx).name = path.accessory(cnt2-prevCnt).name;    
            
            files = dir([path.data, path.accessory(cnt2-prevCnt).name, '/**/*.csv']);
    
            files(contains({files(:).folder}, 'meta')) = [];
            files(contains({files(:).name}, 'Calibration')) = [];
            indices = find(contains({files(:).name}, 'Charging'));
    
            for cnt3 = 1:length(indices)
                idx = indices(cnt3);
    
                tmp = csvread([files(idx).folder, '/', files(idx).name], 1, 0);
                data(cIdx).trial(cnt3).('charging').sample = tmp(:, 1);
            end
            cIdx = cIdx + 1;
        end
        prevCnt = prevCnt + length(path.accessory);
    end
    
    
    result = data;
    
    end

end