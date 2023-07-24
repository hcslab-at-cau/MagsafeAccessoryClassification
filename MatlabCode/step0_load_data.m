clear;

newApp = false;
path = '../Data/';
datasetName = 'Default_dataset';
folderName = 'jaemin3';

path = [path, datasetName, '/', folderName];

c = {'Normal_objects', 'Holders'};
% c = {'subway'};
postfix = char(c);

if newApp == false
    % Phyphox version
    data = func_load_data(path, postfix);
else
    % New app version
    data = func_load_new_data(path, postfix);
end

run('step1_preprocessing.m')
run('step2_detection.m')
run('step2_detection_evaluation.m')
% run('step3_feature_extraction_ground_truth.m')