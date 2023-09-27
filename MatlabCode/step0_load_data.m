clear;

params = struct();
params.data.newApp = true;
params.data.path = '../Data/Inside_dataset/Jaemin7';
params.data.postfix = char({'310'});

data = func_load_data(params.data.path, params.data.postfix);

if params.data.newApp == true
    charging = func_load_charging_status(params.data.path, params.data.postfix);
end

params.objects.name = {'batterypack1', 'griptok1', 'griptok2', 'charger1', 'charger2', 'wallet1',...
    'wallet2', 'wallet3', 'wallet4', 'holder2', 'holder3', 'holder4'};
params.objects.value = [
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
    -18, 75, 10
];


for cnt = 1:length(params.objects)
    objectFeature(cnt).name = char(params.objects.name(cnt));
    objectFeature(cnt).feature = params.objects.value(cnt, :);
end

accNames= {data.name};
objNames = {objectFeature.name};

objectFeature(~ismember(objectFeature.name, data.name)) = [];

% run('step1_preprocessing.m')
% run('step2_detection.m')
% run('step2_detection_evaluation.m')
% run('step3_feature_extraction_ground_truth.m')    