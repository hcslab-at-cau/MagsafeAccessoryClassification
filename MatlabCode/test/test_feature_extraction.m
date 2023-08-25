accId = 7;
trial = 7;

if newApp == false
    groundTruthData = func_load_ground_truth(datasetName, folderName);
end


tmp = data(accId).trial(trial);
rmag = tmp.rmag;
mag = tmp.mag;
gyro = tmp.gyro.sample;

if newApp == false
    groundTruth = groundTruthData.([data(accId).name, '_', num2str(trial)]);
else
    groundTruth = tmp.detect.sample;
end

% 1. calibration at detect
figNum = 15;
disp('test raw diff values')
disp(data(accId).name)
run('test_raw_diff.m')

% 2. initally calibrated data
figNum = figNum + 1;
disp('test calibrated diff values')
run('test_cali_diff.m')

% 3. raw data initally calibrated
figNum = figNum + 1;
disp('test raw calibration diff values')
run('test_raw_cali.m')

%%
accId = 2;
showTrials = 1:4;

if newApp == false
    groundTruthData = func_load_ground_truth(datasetName, folderName);
end

figNum = 30;

for cnt = 1:length(showTrials)
    tmp = data(accId).trial(showTrials(cnt));
    mag = tmp.mag;
    gyro = tmp.gyro.sample;

    if newApp == false
        groundTruth = groundTruthData.([data(accId).name, '_', num2str(showTrials(cnt))]);
    else
        groundTruth = tmp.detect.sample;
    end

    run('test_cali_diff.m')
    figNum = figNum + 1;
end