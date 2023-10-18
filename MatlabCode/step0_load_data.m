clear;

newApp = true;
path = '../Data/';
% datasetName = 'Mobility_dataset';
datasetName = 'Outside_dataset';
folderName = 'Jaemin7';

path = [path, datasetName, '/', folderName];

% c = {'Normal_objects', 'Holders'};
c = {'bus'};
postfix = char(c);

if newApp == false
    % Phyphox version
    data = func_load_data(path, postfix);
else
    % New app version
    data = func_load_new_data(path, postfix);
    charging = func_load_charging_status(path, postfix);
end

idx = ismember({data.name}, {'None'});
if ~isempty(find(idx, 1))
    data = data(~idx);
end


objectFeature = struct();
objects = {'batterypack1', 'griptok1', 'griptok2', 'charger1', 'charger2', 'wallet1',...
    'wallet2', 'wallet3', 'wallet4', 'holder2', 'holder3', 'holder4', 'holder5'};

objectValue = [
    -30, 77, -13;
    -56, 108, -115;
    -20, 44, 11;
    -64, 105, -17;
    -25, 55, 8;
    -26, 54, -9;
    -43, 71, 32;
    -51, 34, -9;
    -23, 50, -23;
    -94, 131, -95;
    -22, 41, -12;
    -18, 75, 10;
    -170, 250, -78
];

for cnt = 1:length(objects)
    objectFeature(cnt).name = char(objects(cnt));
    objectFeature(cnt).feature = objectValue(cnt, :);
end

accNames= {data.name};
objNames = {objectFeature.name};

% objectFeature(~ismember(objNames, accNames)) = [];

run('step1_preprocessing.m')
% run('step2_detection.m')
% run('step2_detection_evaluation.m')
% run('step3_feature_extraction_ground_truth.m')    