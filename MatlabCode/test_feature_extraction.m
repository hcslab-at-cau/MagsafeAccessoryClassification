accId = 4;
trialId = 8;
tmp = data(accId).trial(trialId);
rmag = tmp.rmag;
mag = tmp.mag;
groundTruth = tmp.detect.sample;
gyro = tmp.gyro.sample;


% 1. calibration at detect
figNum = 15;
% disp('test raw diff values')
% disp(data(accId).name)
% run('test_raw_diff.m')

% for k = 1:10
%     trialId = k;
%     tmp = data(accId).trial(trialId);
%     rmag = tmp.rmag;
%     mag = tmp.mag;
%     groundTruth = tmp.detect.sample;
%     gyro = tmp.gyro.sample;
%     disp(data(accId).name)
%     run('test_raw_diff.m')
%     % run('test_cali_diff.m')
% end
% 2. initally calibrated data
figNum = figNum + 1;
disp('test calibrated diff values')
run('test_cali_diff.m')

% % 3. raw data initally calibrated
% figNum = figNum + 1;
% disp('test raw calibration diff values')
% run('test_raw_cali.m')