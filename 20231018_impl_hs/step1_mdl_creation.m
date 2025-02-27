train = load([params.ref.train, '.mat']);
train = train.feature;

chargingAcc = {'charger1', 'charger2', 'charger3', 'holder2', 'holder4', 'batterypack1'};
exceptAcc= {'wallet3', 'holder3'};

portable = {'batterypack1', 'wallet1', 'wallet2', 'wallet4', 'wallet5', 'griptok1', 'griptok2'};
rotatable = {'charger1', 'charger2', 'charger3', 'griptok1', 'griptok2', 'holder4', 'holder5'};
select = {'batterypack1', 'charger3', 'griptok2', 'holder2', 'holder4', 'wallet1', 'wallet2'};
% select = {'charger2a', 'charger2', 'wallet1', 'wallet2', 'wallet1a', 'wallet2a'}

params.ref.rot = 'templates/orientation3_one.mat';
rot = load(params.ref.rot);
rot = rot.feature;

rot(ismember({rot.name}, exceptAcc)) = [];

train = train(~ismember({train.name}, exceptAcc));
% train = train(ismember({train.name}, portable));
nObjs = length(train);


ratio = 0.05;

if ~params.ref.self
    ratio = 1.0;
    test = load([params.ref.test, '.mat']);
    test = test.feature;

    test = test(~ismember({test.name}, exceptAcc));
    params.ref.summary = [params.ref.test, '_summary'];
else
    test = train;
end

summary = load([params.ref.summary, '.mat']);
summary = summary.summary;

% summary.nEvent = summary.nEvent / 2;
o = struct2table(train);
o = sortrows(o, 'name');
train = table2struct(o);

o = struct2table(test);
o = sortrows(o, 'name');
test = table2struct(o);

X = [];
Y = [];

testX = [];
testY = [];

summary.nTrain = zeros(length(summary.b)-1, 2);

% dAcc = [];

% nTrain = 4;
% 
% for cnt = 1:nObjs
%     lResult = length(train(cnt).feature);
% 
%     indices = false(1, lResult);
%     indices(randperm(lResult, nTrain)) = true; % 과거에서 nTrain개만 사용
% 
%     f = [train(cnt).attach;train(cnt).detach];
% 
%     X = [X;f(indices, :)];
%     Y = [Y;repmat({train(cnt).name}, nTrain, 1)];
% 
%     if params.ref.self
%         nIndices = indices(1:length(train(cnt).attach));
%         % nTrain = length(find(nIndices));
% 
%         testX = [testX;train(cnt).attach(~nIndices, :)];
%         testY = [testY;repmat({test(cnt).name}, length(train(cnt).attach)-nTrain, 1)];
% 
%         train(cnt).feature = train(cnt).feature(indices, :);
%         % testX = [testX;train(cnt).feature(~indices, :)];
%         % testY = [testY;repmat({test(cnt).name}, lResult-lTrain, 1)];
%     else
%         lTest = length(test(cnt).feature);
% 
%         indices = false(1, lTest);
%         indices(randperm(lTest, lTrain-nTrain)) = true;
%         nIndices = indices(1:length(test(cnt).attach));
%         lTestTrain = length(find(nIndices));
% 
%         % 현재 dataset에서 lTrain-nTrain 만큼 추가 training
%         X = [X; test(cnt).feature(indices, :)];
%         Y = [Y;repmat({test(cnt).name}, lTrain-nTrain, 1)];
% 
%         % 현재 dataset에서 training에서 사용한 것을 제외한 것을 test(attach)
%         testX = [testX;test(cnt).attach(~nIndices, :)];
%         testY = [testY;repmat({test(cnt).name}, length(test(cnt).attach(~nIndices, :)), 1)];
%     end
% end

for cnt = 1:nObjs
    lResult = length(train(cnt).feature);
    % lTrain = ceil(ratio*lResult);

    indices = false(1, lResult);
    indices(randperm(lResult, lTrain)) = true;

    f = [train(cnt).attach;train(cnt).detach];

    X = [X;f(indices, :)];
    Y = [Y;repmat({train(cnt).name}, lTrain, 1)];

    rotate = rot(ismember({rot.name}, train(cnt).name));

    % if ~isempty(rotate)
    %     X = [X;rotate.feature];
    %     Y = [Y;repmat({train(cnt).name}, length(rotate.feature), 1)];
    % end

    if params.ref.self
        nIndices = indices(1:length(train(cnt).attach));
        nTrain = length(find(nIndices));
        % dAcc(end + 1) = (length(train(cnt).attach)-nTrain)/(nFeature-nTrain);

        testX = [testX;train(cnt).attach(~nIndices, :)];
        testY = [testY;repmat({test(cnt).name}, length(train(cnt).attach)-nTrain, 1)];

        train(cnt).feature = train(cnt).feature(indices, :);

        summary.nTrain(cnt, :) = [nTrain, lTrain-nTrain]; 
        % testX = [testX;train(cnt).feature(~indices, :)];
        % testY = [testY;repmat({test(cnt).name}, lResult-lTrain, 1)];
    else
        if length(test) < cnt
            continue;
        end
        % lTest = length(test(cnt).feature);

        % indices = false(1, lTest);
        % indices(randperm(lTest, lTrain)) = true;
        % nIndices = indices(1:length(test(cnt).attach));
        % nTrain = length(find(nIndices));

        % dAcc(end + 1) = (length(test(cnt).attach)-nTrain)/(nFeature-nTrain);

        % X = [X; test(cnt).feature(indices, :)];
        % Y = [Y;repmat({test(cnt).name}, lTrain, 1)];

        % testX = [testX;test(cnt).attach(~nIndices, :)];
        % testY = [testY;repmat({test(cnt).name}, length(test(cnt).attach(~nIndices, :)), 1)];
        
        % pos = 
% 
        testX = [testX;test(cnt).attach];
        testY = [testY;repmat({test(cnt).name}, length(test(cnt).attach), 1)];
    end
end

lst = {};

nRow = 1;
nCol = length(types);

% fig = figure(1);
% fig.Position(1:4) = [300, 300, 600, 600];


for pos = 1:length(test)
    summary.dAcc(pos, :) = [length(test(pos).attach), length(test(pos).detach)];
end


accuracy = 0;

for cnt = 1:nCol
    type = cell2mat(types(cnt));
    m = fitcecoc(X, Y, "Learners", template.(type));

    [~, scores] = predict(m, testX);
    probs = exp(scores) ./ sum(exp(scores),2);

    % charging status
    preds = func_predict(testX, testY, probs, chargingAcc, train);
    preds = reshape(preds, [length(preds), 1]);
    
    accessory = {train.name};
    % accessory{end + 1} = 'unknown';
    % subplot(nRow, nCol, cnt);
    % c = confusionmat(testY, preds, 'Order', accessory);
    
    % Not detected 
    % cm = confusionchart(c, accessory);
    
    % accuracy(end + 1) = sum(strcmp(testY, preds))/ length(testY) * 100;
    c = func_confusion_matrix(testY, preds, allAcc, {test.name}, summary);
    
    lst{end+1} = m;
end

colNames = {'Accuracy'};
rowNames = [types, 'Average'];

% disp(array2table([accuracy, sum(accuracy)/nCol]', ...
%     'RowNames', rowNames, 'VariableNames', colNames))

% disp(['Average accuracy : ', num2str(accuracy)])

mdl = containers.Map(types, lst);

% for cnt = 1:length(c)
%     c(cnt, :) = c(cnt, :) / sum(c(cnt, :));
% end

return;

%% Accuracy
step0_parameter

SVMOptions = struct("UseParallel",true, "ShowPlots", false, "Verbose", 0);
options = struct("UseParallel",true, "ShowPlots", false, "Verbose", 0);

template.knn = templateKNN('NumNeighbors', 1, 'Standardize', false);
template.linearSVM = templateSVM('Standardize', false, 'KernelFunction', 'linear', 'KernelScale', 1.0, ...
    'BoxConstraint', 1.0, 'SaveSupportVectors', true, 'Solver', 'SMO');

gamma = 0.0001;
kernelScale = 1/sqrt(gamma);

template.rbfSVM = templateSVM('Standardize', false, 'KernelFunction', 'rbf', 'KernelScale', kernelScale, ...
    'BoxConstraint', 1.0, 'SaveSupportVectors', true, 'Solver', 'SMO');

tTree = templateTree('MinLeafSize', 2, 'Surrogate', 'on');
template.tree = templateEnsemble('Bag', 10, tTree);

types = {'knn'};

params.ref.train = 'templates/reference_replace_wallet2';
% params.ref.summary = 'templates/reference_summary'
% params.ref.summary = [params.ref.train, '_summary'];
params.ref.test = 'templates/sh';
params.ref.summary = [params.ref.test, '_summary'];
% params.ref.test = params.ref.train;

params.ref.self = strcmp(params.ref.train, params.ref.test);
% params.ref.self = false;

nFeature = 30;
% lTrains = [1, 3, 5, 10, 20, 30, 60];
lTrains = [5];
results = struct();

totalBar = waitbar(0, 'start');
allAcc = params.global.all;

for lt = 1:length(lTrains)
    tmp = [];
    lTrain = lTrains(lt);
    cumMatrix = zeros(14, 15);

    for n = 1:100
        rng(n)
        step1_mdl_creation

        trainAcc = {train.name};
        testAcc = {test.name};

        % for cnt = 1:length(testAcc)
        %     accName = testAcc(cnt);
        %     idx = find(ismember(trainAcc, accName));
        % 
        %     c(idx, :) = c(idx, :) * dAcc(cnt);
        % end
    
        cumMatrix = cumMatrix + c;

        waitbar(((lt-1) * 100 + n)/(100*length(lTrains)), totalBar, lTrain);
    end

    cumMatrix = cumMatrix / 100;
    
    mt = 0;
    a = [];
    for cnt = 1:size(cumMatrix)
        mt = mt + cumMatrix(cnt, cnt);
        a(end + 1) = cumMatrix(cnt, cnt) * 100;
    end
    
    mt/size(cumMatrix, 1);

    % colNames = {'Detection(A)', 'Identification (A)'};
    colNames = {'Identification'};
    
    % dAcc(end + 1) = mean(dAcc);
    
    % a = rmmissing(a);
    % a(end + 1) = mean(a');
    a(end + 1) = sum(a) / length({test.name});
    rowNames = allAcc;
    rowNames{end + 1} = 'average';
    
    % results(lt).table = array2table([dAcc' * 100, a'], 'VariableNames', colNames, 'RowNames', rowNames);
    results(lt).table = array2table([a'], 'VariableNames', colNames, 'RowNames', rowNames);
    results(lt).cm = cumMatrix;
    % disp(results)
end

a = [];

for cnt = 1:length(results)
    cur = results(cnt);

    a(end + 1) = cur.table.(1)(end);
end

a = round(a', 2)
close(totalBar)