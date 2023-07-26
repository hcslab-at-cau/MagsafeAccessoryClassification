% data load
prefix.train = 'jaemin7_p2p_wSize';
prefix.test = 'jaemin8_p2p';

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);
chargingAcc = [1, 2, 3, 10, 11, 12];


% Drop tables
% dropTable = {'holder3'};
% accNames = {train.name};
% 
% for cnt = 1:length(dropTable)
%     train(contains(accNames, char(dropTable(cnt)))) = [];
%     test(contains(accNames, char(dropTable(cnt)))) = [];
% end


isSame = strcmp(prefix.train, prefix.test);

nAcc = length(train);
nTrainTotal = length(train(1).feature);
nTestTotal = length(test(1).feature);

nTrainCur = 50;
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

    % curTrain = train(cnt).feature(trainIdx, :);
    % curTest = test(cnt).feature(testIdx, :);
    
    range = (cnt - 1) * nTrainCur + (1:nTrainCur);
    featureMatrix.train.data(range, :) = [vertcat(curTrain)];   
    featureMatrix.train.label(range) = cnt;
    
    range = (cnt - 1) * nTestCur + (1:nTestCur);
    featureMatrix.test.data(range, :) = [vertcat(curTest)];
    featureMatrix.test.label(range) = cnt;   
end

result = [];
template.knn = templateKNN('NumNeighbors', 17, 'Standardize', true);
template.svm = templateSVM('Standardize',true);

model.knn = fitcecoc(featureMatrix.train.data, featureMatrix.train.label, ...
    'Learners', template.knn);

model.svm = fitcecoc(featureMatrix.train.data, featureMatrix.train.label);


[predKNN, scoresKNN] = predict(model.knn, featureMatrix.test.data);
[predSVM, scoresSVM] = predict(model.svm, featureMatrix.test.data);
probSVM = exp(scoresSVM) ./ sum(exp(scoresSVM),2);
probKNN = exp(scoresKNN) ./ sum(exp(scoresKNN),2);

%% 
totalAcc = char({train.name});

predSVM = func_considerCharge(featureMatrix.test.label, predSVM, probSVM, totalAcc, chargingAcc);
predKNN = func_considerCharge(featureMatrix.test.label, predKNN, probKNN, totalAcc, chargingAcc);
s1 = sum(predKNN == featureMatrix.test.label) / length(featureMatrix.test.data)
s2 = sum(predSVM == featureMatrix.test.label) / length(featureMatrix.test.data)

order = {train(:).name};

figKNN = figure('Name','KNN','NumberTitle','off');
figKNN.Position(1:4) = [100, 300, 900, 600];
clf

c = confusionmat(featureMatrix.test.label, predKNN);
cm = confusionchart(c, order);
cm.RowSummary = 'row-normalized';
% cm.ColumnSummary = 'column-normalized';

figSVM = figure('Name','SVM','NumberTitle','off');
figSVM.Position(1:4) = [1000, 300, 900, 600];
clf

c = confusionmat(featureMatrix.test.label, predSVM);
cm = confusionchart(c, order);
cm.RowSummary = 'row-normalized';
% cm.ColumnSummary = 'column-normalized';

%% Function for consider charging status
function result = func_considerCharge(label, pred, prob, totalAcc, chargingAcc)
result = pred;

for cnt = 1:length(prob)
    p = prob(cnt, :);
    
    % Real accessory related to charging & Prediction result is related to charging
    if ~isempty(find(ismember(chargingAcc, label(cnt)), 1)) && isempty(find(ismember(chargingAcc, result(cnt)), 1)) 
        % disp(cnt)
        for k = 2:length(p)
            pLabel = find(p == min(maxk(p, k)));

            if ~isempty(find(ismember(chargingAcc, pLabel), 1))
                % disp(['result has been changed 1  ', num2str(result(cnt)), ' to ', num2str(pLabel)])
                % disp([num2str(cnt), '_ ', num2str(pLabel)])
                tmp = pLabel;
                if length(pLabel) ~= 1
                    for cnt2 = 1:length(pLabel)
                        if ~isempty(find(ismember(chargingAcc, pLabel(cnt2)), 1))
                            tmp = pLabel(cnt2);
                            break;
                        end
                    end
                end

                result(cnt) = tmp;
                break;
            end
        end
    % Real accessory is not related to charging & Prediction result is related to charging
    elseif isempty(find(ismember(chargingAcc, label(cnt)), 1)) && ~isempty(find(ismember(chargingAcc, result(cnt)), 1)) 
        for k = 2:length(p)
            pLabel = find(p == min(maxk(p, k)));

            if isempty(find(ismember(chargingAcc, pLabel), 1))
                % disp(['result has been changed 2  ', num2str(result(cnt)), ' to ', num2str(pLabel)])
                % disp([num2str(cnt), '_ ', num2str(pLabel)])
                result(cnt) = pLabel;
                break;
            end
        end
    end
end

end

