%% Run all directories
clear;

global params;
params = struct();

% params.data.path = '../Data/Inside/1';
% params.data.postfixs = {'524', '208', '310Stair', 'airport'};
% params.data.postfixs = {'208', '310Stair'};
% params.data.postfixs = {'524', 'airport'};
% params.data.postfixs = {'310'};

% params.data.path = '../Data/PublicTransport/1';
% params.data.postfixs = {'train', 'bus'};
% params.data.postfixs = {'subway'};
% params.data.postfixs = {'car', 'subway', 'ktx'};

params.data.path = '../Data/Mobility/1';
% % params.data.postfixs = {'ground', 'stair'};
params.data.postfixs = {'ground'};
% 
% params.data.path = '../Data/electronicDevice/1';
% params.data.postfixs = {'laptop'};

% params.data.fPath = '../Data/User/';
% params.data.paths = 11;
% params.data.postfix = char({'Normal_objects', 'Holders'}); 

% params.data.path = '../Data/InsideOffice/1';
% params.data.postfixs = {'jm'};

% 
% params.data.fPath = '../Data/Orientation/';
% params.data.paths = 3;
% params.data.postfix = char({'Normal_objects', 'Holders'});

% params.data.fPath = '../Data/Default/';
% params.data.paths = 6;
% params.data.postfix = char({'Normal_objects', 'Holders'});

% params.data.fPath = '../Data/Device/iPhone12Pro';
% params.data.paths = 1;
% params.data.postfix = char({'Normal_objects', 'Holders'});

% params.data.fPath = '../Data/Figure/1';
% params.data.paths = 1;
% params.data.postfix = char({'1'});

% params.data.fPath = '../Data/Trivial/acc_test';
% params.data.paths = 2;
% params.data.postfix = char({'Normal_objects'});

params.global.repeat = 1;
params.ref.path = 'templates/reference_replace_wallet2';
params.ref.self = false;
params.ref.all = true;

ratioNumber = 5;

% types = {'knn', 'linearSVM', 'tree'};
types = {'knn'};

averageResult = struct();

for path = params.data.postfixs
    pathIdx = find(strcmp(path, params.data.postfixs));
    params.data.postfix = char(path);
    disp(['Start - ', params.data.path, '/', char(path)])

% for path = 1:params.data.paths
% for path = 2
%     pathIdx = path;
%     % params.data.path = [params.data.fPath, num2str(path)];
%     params.data.path = params.data.fPath;
%     disp(['Start - ', params.data.path])

%     if path == 3
%         continue;
%     end

% totalBar = waitbar(0, 'Start');
% 
% allPaths = func_get_all_paths();
% 
% for pathIdx = 1:length(allPaths)
%     params.data.path = allPaths(pathIdx).root;
%     params.data.postfix = allPaths(pathIdx).postfix;
%     params.ref.path = func_matched_reference(params.data.postfix);
%     disp(['Start - ', params.data.path, '/' ,params.data.postfix])

    step0_initialization
    step0_parameter
    step1_preprocessing

    localResult = struct();

    for repeat = 1:params.global.repeat    
        disp(['REPEAT ', num2str(repeat), 'th -ing'])
        table = [];
        rng(repeat)

        % waitbar(((pathIdx - 1) * params.global.repeat + repeat)/(length(allPaths) * params.global.repeat), totalBar, [params.data.path, '/' ,params.data.postfix]);
        % params.ref.path = ['features/user/', num2str(pathIdx), '.mat'];

        [mdls, ref] = func_make_model(params.ref.path, ratioNumber, types);
        ref = func_reference_update(ref, params);

        for tk = 1:length(types)
            type = types(tk);
    
            if params.ref.all
                mdl = mdls(char(type));
    
                step2_identification_all_mdl
                step3_evaluation_all
            else
                if strcmp(path, 'airport')
                    mdl = load(['./mdl/ref/portable_exclude_batterypack/', char(type), '.mat']);
                else
                    mdl = load(['./mdl/ref/all_gamma0001/', char(type), '.mat']);
                end
                mdl = mdl.m;
    
                step2_2_identification_mdl
                step3_evaluation
            end

            localResult(tk + (repeat-1)*length(types)).method = char(type);
            localResult(tk + (repeat-1)*length(types)).average = table2array(table(end, :));
            localResult(tk + (repeat-1)*length(types)).m = m;
        end
    end

    % averageResult(pathIdx).name = [params.data.path, '/', params.data.postfix];

    averageResult(pathIdx).name = params.data.path;
    averageResult(pathIdx).result = localResult;
    
    % step2_3_extract_feature
    % feature = features;
    % 
    % % baseName = ['user', num2str(pathIdx)];
    % baseName = 'iPhone12Pro_MagAcc';
    % save(['./templates/', baseName,'.mat'], 'feature')
    % save(['./templates4/reference', num2str(pathIdx), '.mat'], 'feature')

    % save(['./templates/', baseName, '_summary.mat'], 'summary')
end

% close(totalBar)
%% Plot accuracy
colNames = {'Detection (A)', 'Detection  (D)', 'Classification', 'Identification', 'False Positive', 'FP(A)', 'FP(D)'};
pathNames = [];
averages = struct();
a = [];

for cnt = 1:length(averageResult)
    cur = averageResult(cnt).result;
    average = [];

    if isempty(cur)
        continue;
    end

    for type = types
        % tmp = cur(ismember({cur.method}, type));
        tmp = cur(strcmp({cur.method}, type));
        lst = [];

        for cnt2 = 1:length(tmp)
            lst(end + 1, :) = tmp(cnt2).average;
        end

        average(end + 1, :) = mean(lst, 1);
    end
    
    averages(cnt).name = averageResult(cnt).name;
    averages(cnt).average = average;
    
    results = array2table(average, 'VariableNames', colNames, 'RowNames', types);
    
    res = [];
    
    for cnt2 = 1:size(average, 1) / length(types)
        tmp = [];
        for cnt3 = 1:length(types)
           tmp = [tmp, average((cnt2-1)*length(types) + cnt3, :)]; 
        end
        res = [res; tmp];
    end
    
    res = round(res, 4);

    disp(char(averages(cnt).name))
    disp(results)

    averages(cnt).table = results;
    averages(cnt).res = res;
    a = [a;res];
end

return;