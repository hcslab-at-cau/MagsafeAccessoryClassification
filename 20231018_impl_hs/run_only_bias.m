%% Only repeat bias
step0_initialization
step0_parameter
step1_preprocessing

[mdls, ref] = func_make_model([params.ref.path, '.mat'], ratioNumber, types);
ref = func_reference_update(ref, params);

mdl = mdls('knn');

step2_identification_all_mdl
step3_evaluation_all

table = table2array(table(end, :));
testLabels = {ori.name};

tmp = summary.iAcc .* summary.nEvent;
summary.dAcc(:, 2) = tmp(:, 2);

tmp = summary.dAcc .* summary.nEvent;
summary.dAcc(:, 1) = tmp(:, 1);
%%
results = struct();

parfor repeat = 1:params.global.repeat
    rng(repeat)

    resultSum = 0;
        c = zeros(14, 14);

    [mdls, ref] = func_make_model([params.ref.path, '.mat'], ratioNumber, types);
    ref = func_reference_update(ref, params);

    mdl = mdls('knn');
    
    Y = [];
    preds = [];
    
    for k = 1:length(biasResult)
        bias = biasResult(k).bias;
        accName = biasResult(k).name;
        idx = find(ismember(allAcc, accName));
        
        if isempty(bias)
            continue
        end

        [~, scores] = predict(mdl, bias);
        probs = exp(scores) ./ sum(exp(scores),2);
        
        if size(bias, 1) == 1
            [probsx, identified] = sort(probs, 'descend');
            identified = allAcc(identified);

            % identified(xor(ismember(accName, params.global.chargable), ismember(identified, params.global.chargable))) = [];
        else
            [probsx, identified] = sort(probs', 'descend');
            identified = allAcc(identified)';

            % tmp = [];
            % 
            % for bs = 1:size(bias, 1)
            %     tmp{end + 1} = identified(bs, ~xor(ismember(accName, params.global.chargable), ismember(identified(bs, :), params.global.chargable)));
            % end
            % 
            % identified = [];
            % 
            % for bs = 1:length(tmp)
            %     identified = [identified;tmp{bs}];
            % end
        end
        
        identified = identified(:, 1);
        
        if sum(strcmp(identified, accName)) > 0
            % correctly identified.
            pIdx = find(ismember(allAcc, accName));
            resultSum = resultSum + 1;
            preds{end + 1} = accName;
        else
            % incorrectly
            pIdx = find(ismember(allAcc, identified(1)));
            preds{end + 1} = cell2mat(identified(1));
        end

        Y{end + 1} = accName;
        c(idx, pIdx) = c(idx, pIdx) + 1;
    end

    resultSum = resultSum / length(biasResult) * 100;

    results(repeat).identification = resultSum;
    results(repeat).cm = func_confusion_matrix(Y, preds, allAcc, testLabels, summary);
    
    % waitbar(repeat/params.global.repeat, totalResult, [num2str(repeat), '/', num2str(params.global.repeat)]);
end

return;
%% Only repeat bias
clear;

global params;
params = struct();

params.data.path = '../Data/Inside/1';
params.data.postfixs = {'310'};

% params.data.path = '../Data/PublicTransport/1';
% % params.data.postfixs = {'train', 'bus'};
% params.data.postfixs = {'ktx'};
% params.data.postfixs = {'car', 'subway', 'ktx'};

% params.data.path = '../Data/Mobility/1';
% params.data.postfixs = {'ground', 'stair'};
% params.data.postfixs = {'ground'};
% 
% params.data.path = '../Data/electronicDevice/1';
% params.data.postfixs = {'laptop'};

% params.data.fPath = '../Data/User/';
% params.data.paths = 11;
% params.data.postfix = char({'Normal_objects', 'Holders'}); 

% params.data.fPath = '../Data/Orientation/';
% params.data.paths = 3;
% params.data.postfix = char({'Normal_objects', 'Holders'});

% params.data.fPath = '../Data/Default/';
% params.data.paths = 6;
% params.data.postfix = char({'Normal_objects', 'Holders'});

% params.data.fPath = '../Data/Device/iPhone12_case';
% params.data.paths = 1;
% params.data.postfix = char({'Normal_objects', 'Holders'});

% params.data.fPath = '../Data/Feasibility/';
% params.data.paths = 2;
% params.data.postfix = char({'Normal_objects'});

params.global.repeat = 100;
% params.ref.path = 'templates/user';
% params.ref.summary = [params.ref.path, '_summary'];
params.ref.path = 'templates/reference_replace_wallet2'
params.ref.self = false;
params.ref.all = true;

% params.ref.user = 'templates/user';

ratioNumber = 5;
types = {'knn'};

totalResult = struct();
totalBar = waitbar(0, 'start');

% paths = size(params.data.postfixs, 1);
% for path = params.data.postfixs
%     pathIdx = find(strcmp(path, params.data.postfixs));
%     params.data.postfix = char(path);
%     disp(['Start - ', params.data.path, '/', char(path)])

% paths = params.data.paths
% for path = 1:params.data.paths
% % for path = 2
%     pathIdx = path;
%     params.data.path = [params.data.fPath, num2str(path)];
%     % params.data.path = params.data.fPath;
%     params.ref.path = [params.ref.user, num2str(path)];
%     disp(['Start - ', params.data.path])

    % if path == 2
    %     continue;
    % end

allPaths = func_get_all_paths();
paths = length(allPaths);

% summary = load([params.ref.summary, '.mat']);
% summary = summary.summary;

for pathIdx = 1:length(allPaths)
    params.data.path = allPaths(pathIdx).root;
    params.data.postfix = allPaths(pathIdx).postfix;
    params.ref.path = func_matched_reference(params.data.postfix);
    disp(['Start - ', params.data.path, '/' ,params.data.postfix])
    
    % if size(params.data.postfix, 1) == 1
    %      wbar = waitbar(0, [params.data.path, '/' , params.data.postfix]);
    % else
    %      wbar = waitbar(0, params.data.path);
    % end

    run_only_bias
    
    % close(wbar)
    
    totalResult(pathIdx).table = table;
    totalResult(pathIdx).result = results;
    totalResult(pathIdx).testLabels = testLabels;

    if size(params.data.postfix, 1) == 1
        totalResult(pathIdx).path = [params.data.path, '/' , params.data.postfix];
    else
        totalResult(pathIdx).path = params.data.path;
    end

    waitbar(pathIdx/paths, totalBar, totalResult(pathIdx).path);
end

close(totalBar)
%%
rowNames = {totalResult.path};
% 
% rowNames(2) = []
colNames = {'Detection (A)', 'Detection (D)', 'Classification', 'Identification', 'False Positive', 'FP(A)', 'FP(D)'};

average = [];
identification = [];
tables = [];

for cnt = 1:length(totalResult)
    cur = totalResult(cnt).result;
    if isempty(cur)
        continue;
    end

    average(end + 1) = mean(cell2mat({cur.identification}));
    
    cm = zeros(14, 15);

    for cnt2 = 1:length(cur)
        cm = cm + cur(cnt2).cm;
    end

    a = 0;
    for cnt2 = 1:size(cm, 1)
        a = a + cm(cnt2, cnt2);
    end

    identification(end + 1) = a / length(totalResult(cnt).testLabels);
    tables = [tables;totalResult(cnt).table];
end
a = round([tables(:, 1:2), average', identification', tables(:, end-2:end)], 4);

a = array2table(a, ...
    'VariableNames', colNames, ...
    'RowNames', rowNames);

disp(a)