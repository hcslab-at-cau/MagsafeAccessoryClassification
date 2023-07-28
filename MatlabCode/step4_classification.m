% data load
prefix.train = 'jaemin9_p2p';
prefix.test  = 'jaemin9_p2p';

train = func_load_feature(prefix.train);
test = func_load_feature(prefix.test);

% Template init
template.knn = templateKNN('NumNeighbors', 21, 'Standardize',true);
template.svm = templateSVM('Standardize',true);

[model.knn, pred, prob] = func_train_model(template.knn, train, test, 25);


