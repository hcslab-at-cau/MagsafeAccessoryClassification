% run('step0_load_data.m')
clear;

path = '../Data/';
datasetName = 'Orientation_dataset';
folderName = 'jaemin2';
path = [path, datasetName, '/', folderName];

postfix = char({'objects'});
data = func_load_new_data(path, postfix);

% for cnt = 1:length(orientData)
%     originAcc = {data.name};
%     curName = orientData(cnt).name;
%     idx = find(ismember(originAcc, curName), 1);
% 
%     data(idx).trial = orientData(cnt).trial;
% end
newApp = true;

run('step1_preprocessing.m')
run('step2_detection.m')
run('step2_detection_evaluation.m')
run('step3_feature_extraction_ground_truth.m')

% featureName = [folderName, '_p2p'];
% run('step4_classification.m')