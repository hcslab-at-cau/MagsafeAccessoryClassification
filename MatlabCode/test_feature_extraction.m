accId = 6;
trialId = 10;

tmp = data(accId).trial(trialId);
rmag = tmp.rmag;
mag = tmp.mag;
groundTruth = tmp.detect.sample;
gyro = tmp.gyro.sample;
disp(data(accId).name)

% 1. calibration at detect
figNum = 10;
disp('test raw diff values')
run('test_raw_diff.m')

% 2. initally calibrated data
figNum = figNum + 1;
disp('test calibrated diff values')
run('test_cali_diff.m')

% 3. raw data initally calibrated
figNum = figNum + 1;
disp('test raw calibration diff values')
run('test_raw_cali.m')