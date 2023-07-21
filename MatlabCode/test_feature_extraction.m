accId = 10;
showTrials = 1:10;

if newApp == false
        groundTruthData = func_load_ground_truth(datasetName, folderName);
end

% 1. calibration at detect
figNum = 15;
% disp('test raw diff values')
disp(data(accId).name)
% run('test_raw_diff.m')


for cnt = 1:length(showTrials)
    tmp = data(accId).trial(showTrials(cnt));
    % rmag = tmp.rmag;
    mag = tmp.mag;
    
    if newApp == false
        groundTruth = groundTruthData.([data(accId).name, '_', num2str(showTrials(cnt))]);
    else
        groundTruth = tmp.detect.sample;
    end
    
    gyro = tmp.gyro.sample;
    
    run('test_cali_diff.m')
    figNum = figNum + 1;
end
% 2. initally calibrated data
% figNum = figNum + 1;
% disp('test calibrated diff values')
% run('test_cali_diff.m')

% % 3. raw data initally calibrated
% figNum = figNum + 1;
% disp('test raw calibration diff values')
% run('test_raw_cali.m')