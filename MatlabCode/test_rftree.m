% Load the Fisher iris dataset
load fisheriris

% Define predictors and response
predictors = meas;
response = species;

% Create a templateTree
t = templateTree('MaxNumSplits', 5); % You can customize the parameters of your tree.

% Train the classifier
randomForestModel = fitcensemble(predictors, response, 'Method', 'Bag', 'NumLearningCycles', 30, 'Learners', t);

% View the trained model
view(randomForestModel.Trained{1}, 'Mode', 'graph');
