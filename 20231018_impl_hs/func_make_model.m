function [mdl, feature] = func_make_model(path, ratioNumber, types)
template.knn = templateKNN('NumNeighbors', 1, 'Standardize', false);
template.linearSVM = templateSVM('Standardize', false, 'KernelFunction', 'linear', 'KernelScale', 1.0, ...
    'BoxConstraint', 1.0, 'SaveSupportVectors', true, 'Solver', 'SMO');

gamma = 0.0001;
kernelScale = 1/sqrt(gamma);

template.rbfSVM = templateSVM('Standardize', false, 'KernelFunction', 'rbf', 'KernelScale', kernelScale, ...
    'BoxConstraint', 1.0, 'SaveSupportVectors', true, 'Solver', 'SMO');

tTree = templateTree('MinLeafSize', 2, 'Surrogate', 'on');
template.tree = templateEnsemble('Bag', 5, tTree);

exceptAcc= {'wallet3', 'holder3'};
train = load(path);
train = train.feature;

train(ismember({train.name}, exceptAcc)) = [];

o = struct2table(train);
o = sortrows(o, 'name');
train = table2struct(o);

X = [];
Y = [];
feature = struct();

for cnt = 1:length(train)
    feature(cnt).name = train(cnt).name;
    lResult = length(train(cnt).feature);

    % lTrain = ceil(ratio*lResult);
    lTrain = min(ratioNumber, lResult);

    indices = false(1, lResult);
    indices(randperm(lResult, lTrain)) = true;
 
    X = [X;train(cnt).feature(indices, :)];
    Y = [Y;repmat({train(cnt).name}, lTrain, 1)];

    feature(cnt).feature = train(cnt).feature(indices, :);
end

lst = {};

nCol = length(types);

for cnt = 1:nCol
    type = cell2mat(types(cnt));
    m = fitcecoc(X, Y, "Learners", template.(type));

    lst{end+1} = m;
end

mdl = containers.Map(types, lst);

end