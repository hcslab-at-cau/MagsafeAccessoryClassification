testModel = model.knn;
% testData = [1, 2, 2];
testData = [-10, 70, 11];

[testPred, scores] = predict(testModel, testData);

% Get probability of each label
testProb = exp(scores) ./ sum(exp(scores),2);

testProb
testPred