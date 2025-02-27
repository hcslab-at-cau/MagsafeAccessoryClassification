% Model parameter loading
clear;

global params;
params = struct();

% params.data.path = '../Data/User/1';
params.data.path = '../Data/Default/2';
params.data.postfix = char({'Normal_objects', 'Holders'});
% types = {'knn', 'linearSVM', 'rbfSVM'};
types = {'knn'};

step0_initialization
step1_preprocessing

params.ref.path = 'templates/reference';
params.ref.summary = [params.ref.path, '_summary'];

[~, ref] = func_make_model(params.ref.path, 120, types);
ref = func_reference_update(ref, params);

template.knn = templateKNN('NumNeighbors', 1, 'Standardize', false);
template.linearSVM = templateSVM('Standardize', false, 'KernelFunction', 'linear', 'KernelScale', 1.0, ...
    'BoxConstraint', 1.0, 'SaveSupportVectors', true, 'Solver', 'SMO');

gamma = 0.0001;

template.rbfSVM = templateSVM('Standardize', false, 'KernelFunction', 'rbf', 'KernelScale', 1/sqrt(gamma), ...
    'BoxConstraint', 1.0, 'SaveSupportVectors', true, 'Solver', 'SMO');

params.ref.train = params.ref.path;
params.ref.test = params.ref.path;
params.ref.self = strcmp(params.ref.train, params.ref.test);
% params.ref.self = false;
params.global.repeat = 1;

params.data.train = load(params.ref.train);
params.data.train = params.data.train.feature;

params.data.summary = load(params.ref.summary);
params.data.summary = params.data.summary.summary;

chargingAcc = {'charger1', 'charger2', 'charger3', 'holder2', 'holder4', 'batterypack1'};
exceptAcc= {'wallet3', 'holder3', 'None'};

portable = {'wallet1', 'wallet2', 'wallet4', 'wallet5', 'griptok1', 'griptok2', 'batterypack1'};
rotatable = {'charger1', 'charger2', 'charger3', 'griptok1', 'griptok2', 'holder4', 'holder5'};

params.data.train = params.data.train(~ismember({params.data.train.name}, exceptAcc));
% tmp = params.data.train(params.data.train())


% params.data.summary = func_exclude_summary(params.data.summary, );

% ratio = 0.8;
ratioNumber = 5;

if ~params.ref.self
    ratio = 1.0;
    params.data.test = load(params.ref.test);
    params.data.test = params.data.test.feature;

    params.data.test = params.data.test(~ismember({params.data.test.name}, exceptAcc));
else
    params.data.test = params.data.train;
end

o = struct2table(params.data.train);
o = sortrows(o, 'name');
params.data.train = table2struct(o);

o = struct2table(params.data.test);
o = sortrows(o, 'name');
params.data.test = table2struct(o);

%% Table load
T = readmatrix('accessory_optim_final.xlsx');

% order = ["batterypack", "holder", "holder", "wallet", "wallet", ...
%     "griptok", "charger", "charger"];

order = ["batterypack", "cooler", "wallet", "griptok", "charger", "holder"];

origin = struct();
origin.data = data;
origin.ref = ref;
origin.ori = ori;
origin.feature = feature;

result = struct();
%% Split, Training, Test
idx = 0;

for trial = 1:size(T, 1)
    curAcc = strings(1, length(order));
    
    for cnt2 = 1:length(order)
        if order(cnt2) == "cooler"
            curAcc(cnt2) = "cooler";
            continue
        end

        curAcc(cnt2) = order(cnt2) + num2str(T(trial, cnt2));
    end
    
    disp([num2str(trial), '/', num2str(size(T, 1)), ' %'])
    curAcc = convertStringsToChars(curAcc);
    
    params.global.nObjects = length(curAcc);
    params.global.all = sort(curAcc);
    
    % Split train and test data 
    X = params.data.train(ismember({params.data.train.name}, curAcc));
    Y = params.data.test(ismember({params.data.test.name}, curAcc));
    summary = params.dat.summary

    if length(X) ~= length(curAcc)
        disp("X is not certain length")
        break;
    end
   
    for repeat = 1:params.global.repeat
        rng(repeat)

        trainX = [];
        trainY = [];
        
        testX = [];
        testY = [];
        for cnt2 = 1:length(X)
            lResult = length(X(cnt2).feature);
            % lTrain = ceil(ratio*lResult);
            lTrain = ratioNumber;
    
            indices = false(1, lResult);
            indices(randperm(lResult, lTrain)) = true;
         
            trainX = [trainX;X(cnt2).feature(indices, :)];
            trainY = [trainY;repmat({X(cnt2).name}, lTrain, 1)];
        
            if params.ref.self
                testX = [testX;X(cnt2).feature(~indices, :)];
                testY = [testY;repmat({Y(cnt2).name}, lResult-lTrain, 1)];
            else
                testX = [testX;Y(cnt2).feature];
                testY = [testY;repmat({Y(cnt2).name}, length(Y(cnt2).feature), 1)];
            end
        end
        
        % Train data
        lst = {};
        accuracy = [];

        for cnt2 = 1:length(types)
            type = cell2mat(types(cnt2));
            m = fitcecoc(trainX, trainY, "Learners", template.(type));
            [~, scores] = predict(m, testX);
            probs= exp(scores) ./ sum(exp(scores),2);

            % charging status
            preds = func_predict(testX, testY, probs, chargingAcc, {X.name});
            preds = reshape(preds, [length(preds), 1]);
            func_predict(testX, testY, probs, chargingAcc, train);

            accuracy(end + 1) = sum(strcmp(testY, preds))/ length(testY) * 100;

            lst{end+1} = m;
        end
    
        mdls = containers.Map(types, lst);
        disp(accuracy)
    
        % Parsing with acc 
        data = origin.data(ismember({origin.data.name}, curAcc));
        ref = origin.ref(ismember({origin.ref.name}, curAcc));
        ori = origin.ori(ismember({origin.ori.name}, curAcc));
        feature = origin.feature(ismember({origin.feature.name}, curAcc));
        params.data.nObjects = length(data);
     
        % step2_identification_all
        % step3_evaluation_all
    
        for trial2 = 1:length(types)
            type = cell2mat(types(trial2));
            
            mdl = mdls(type);
            step2_identification_all_mdl
            step3_evaluation_all   
    
            % idx = trial2 + (trial - 1)* length(types);
            idx = idx + 1;
            result(idx).method = type;
            result(idx).result = table2array(table(end, :));
        end
    end
end

%% Show accuracy

colNames = {'Detection (A)', 'Detection  (D)', 'Identification', 'False Positive', 'FP(A)', 'FP(D)'};
% types = {'knn', 'linearSVM', 'rbfSVM'};
pathNames = [];
averages = [];
a = [];

for cnt = 1:length(types)
    type = types(cnt);

    cur = result(strcmp({result.method}, type));
    average = [];
    
    for cnt2 = 1:length(cur)
        average(end + 1, :) = cur(cnt2).result;
    end

    average = mean(average, 1);
    averages = [averages; average];
end

results = array2table(averages, 'VariableNames', colNames, 'RowNames', types);
a = [];

for cnt = 1:size(averages, 1)
    a = [a, averages(cnt, :)];
end

a = round(a * 100, 3);

disp(results)


%% With only identification accuracy
T = readmatrix('accessory_optim_final.xlsx');

order = ["batterypack", "cooler", "wallet", "griptok", "charger", "holder"];

params.ref.train = 'templates/reference';
params.ref.summary = [params.ref.train, '_summary'];
params.ref.test = params.ref.train;

params.ref.self = strcmp(params.ref.train, params.ref.test);

types = {'knn'};
params.global.repeat = 100;
nFeature = 60;
lTrain = 5;

chargingAcc = {'charger1', 'charger2', 'charger3', 'holder2', 'holder4', 'batterypack1'};
exceptAcc= {'wallet3', 'holder3', 'None'};
template.knn = templateKNN('NumNeighbors', 1, 'Standardize', false);

train = load([params.ref.train, '.mat']);
train = train.feature;

train = train(~ismember({train.name}, exceptAcc));

summary = load([params.ref.summary, '.mat']);
summary= summary.summary;

summary = func_include_summary(summary, {train.name});

if ~params.ref.self
    test = load(params.ref.test);
    test = test.feature;

    test = test(~ismember({test.name}, exceptAcc));
else
    test = train;
end


step0_parameter

% Results
result = struct();
idx = 0;

for trial = 1:size(T, 1)
    disp([num2str(trial), '/', num2str(size(T, 1)), ' %'])

    curAcc = strings(1, length(order));
    
    for cnt2 = 1:length(order)
        if order(cnt2) == "cooler"
            curAcc(cnt2) = "cooler";
            continue
        end

        curAcc(cnt2) = order(cnt2) + num2str(T(trial, cnt2));
    end
    
    curAcc = sort(convertStringsToChars(curAcc));
    
    % Split train and test data 
    curTrain = train(ismember({train.name}, curAcc));
    curTest = test(ismember({test.name}, curAcc));
    curSummary = func_include_summary(summary, curAcc);

    o = struct2table(curTrain);
    o = sortrows(o, 'name');
    curTrain = table2struct(o);
    
    o = struct2table(curTest);
    o = sortrows(o, 'name');
    curTest = table2struct(o);

    if length(curTrain) ~= length(curAcc)
        disp("X is not certain length")
        break;
    end

    for repeat = 1:params.global.repeat
        rng(repeat)

        X = [];
        Y = [];
        
        testX = [];
        testY = [];
    
        dAcc = [];
        nTest = [];
        
        % Ran train, test data
        for cnt = 1:length(curTrain)
            lResult = length(curTrain(cnt).feature);
            
            indices = false(1, lResult);
            indices(randperm(lResult, lTrain)) = true;
        
            f = [curTrain(cnt).attach;curTrain(cnt).detach];
            
            X = [X;f(indices, :)];
            Y = [Y;repmat({curTrain(cnt).name}, lTrain, 1)];
        
            if params.ref.self
                nIndices = indices(1:length(curTrain(cnt).attach));
                nTrain = length(find(nIndices));
                % dAcc(end + 1) = (length(curTrain(cnt).attach)-nTrain)/(nFeature-nTrain);
        
                testX = [testX;curTrain(cnt).attach(~nIndices, :)];
                testY = [testY;repmat({curTrain(cnt).name}, length(curTrain(cnt).attach)-nTrain, 1)];
                nTest(end + 1) = sum(~nIndices);
            else
                % if length(curTest) < cnt
                %     continue;
                % end
        
                % dAcc(end + 1) = (length(curTest(cnt).attach))/(nFeature);
                nTest(end + 1) = length(curTest(cnt).attach);
        
                testX = [testX;curTest(cnt).attach];
                testY = [testY;repmat({curTest(cnt).name}, length(curTest(cnt).attach), 1)];
            end
        end
        
        % Model train & test
        m = fitcecoc(X, Y, "Learners", template.knn);
        [~, scores] = predict(m, testX);
        probs = exp(scores) ./ sum(exp(scores),2);
    
        preds = func_predict(testX, testY, probs, chargingAcc, curTrain);
        preds = reshape(preds, [length(preds), 1]);

        % cm = confusionmat(testY, preds, 'Order', {curTrain.name});
        accuracy = sum(strcmp(testY, preds))/ length(testY) * 100;
        cm = func_confusion_matrix(testY, preds, {curTest.name}, {curTest.name}, curSummary);

        a = 0;
        for cs = 1:size(cm, 1)
            a = a + cm(cs, cs);
        end

        a = a / size(cm, 1);
        
        idx = idx + 1;
        result(idx).detection = dAcc;
        result(idx).accuracy = a;
        result(idx).overall = curSummary;
        result(idx).cm = cm;
        result(idx).order = {curTrain.name};
    end
end

colNames = {'Detection', 'Identification', 'overall'};

colNames = {'Identification'};

% results = array2table([mean(cell2mat({result.detection}) * 100), mean(cell2mat({result.accuracy})), ...
%     mean(cell2mat({result.overall}))], 'VariableNames', colNames, 'RowNames', types);

results = array2table([mean(cell2mat({result.accuracy}))], 'VariableNames', colNames, 'RowNames', types);
disp(results)

cmat = zeros(6, 6);

for cnt = 1:length(result)
    cmat = cmat + result(cnt).cm;
end

% fig = figure(5);
% fig.Position(1:2) = [100, 100];
% cm = confusionchart(cmat, sort(order));
%% 
disp("start")

a = [];
for cnt = 1:size(cmat, 1)
    a(end + 1) = cmat(cnt, cnt) / sum(cmat(cnt, :));
end

a = a * 100;
a = a'
%%

% su = func_exclude_summary(summary, {'griptok2'});
%%
function summary = func_include_summary(summary, include)

indices = ismember(summary.labels, include);

field = fieldnames(summary);

for cnt = 1:size(field, 1)
    if strcmp(field{cnt}, 'labels')
        summary.(field{cnt})(~indices) = [];
    else
        summary.(field{cnt})(~indices, :) = [];
    end
end
end