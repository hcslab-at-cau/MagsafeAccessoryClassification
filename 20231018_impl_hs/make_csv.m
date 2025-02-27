% Make CSV
params.ref.path = "templates2/reference_replace_wallet2.mat";

load("templates2/reference_replace_wallet2.mat");
excepts = {'wallet3', 'holder3'};
select = {'wallet1', 'charger1', 'wallet2', 'holder4'};
chargable = {'batterypack1', 'charger1', 'charger2', 'charger3', 'holder2', ... 
            'holder3', 'holder4'};

dir = 'csv/';

% feature(~ismember({feature.name}, select)) = [];
% [~, ref] = func_make_model(params.ref.path, 5, types);
% ref = func_reference_update(ref, params);

arr = [];

lTrain = 5;
for cnt = 1:length(feature)
    cur = feature(cnt);
    lResult = length(cur.feature);

    indices = false(1, lResult);
    indices(randperm(lResult, lTrain)) = true;

    cur.name

    arr = [arr; repmat(cnt, lTrain, 1), cur.feature(indices, :)];
    % writetable(array2table(feature(cnt).feature), [dir, feature(cnt).name, '.csv'])
end

% writetable(array2table(feature(cnt).feature), [dir, feature(cnt).name, '.csv'])
writetable(array2table(arr), [dir, 'template_all', '.csv'])