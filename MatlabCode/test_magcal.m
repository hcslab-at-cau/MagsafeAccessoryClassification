accId = 2;
trial = 1;

tmp = data(accId).trial(trial);
mag = tmp.mag;
gyro = tmp.gyro;
rmag = tmp.rmag;
range = 1:200;
    
figure(9)
clf

nCol = length(trial);
nRow = 4;

subplot(nRow, nCol, 1)
plot(rmag.sample)
title('raw mag values')

subplot(nRow, nCol, 2)
plot(mag.sample)
title('calibrated mag values')

% Magnetometer bias calculation using magcal
% Calibrated_data = (Raw_data-bias1) * calibration_matrix
% Assume Calibrated_data = Raw_data * calibration_matrix + bias2
% bias2 = -bias1*calibration_matrix
[A, b, expmfs] = magcal(rmag.sample(range, :));

bias = - b * A;
calibrated_data = zeros(length(rmag.sample), 3);

for cnt = 1:length(calibrated_data)
    calibrated_data(cnt, :) = (rmag.sample(cnt, :) - b)*A;
    % calibrated_data(cnt, :) = rmag.sample(cnt, :) - b;
end

subplot(nRow, nCol, 3)
plot(calibrated_data)
title('calibrated mag using magcal (Estimated)')


% Magnetometer bias calculation using equation
% Calibration_data = Raw_data * calibration_matrix + bias
% = Raw_data * matrix
rRange = range;

rawData = rmag.sample(range, :);
calibratedData = mag.sample(rRange, :);
rawDatas = [rawData, ones(size(rawData, 1), 1)];
matrix = rawDatas \ calibratedData;

calibrationMatrix = matrix(1:3, :);
bias = matrix(4, :);

calibrated_data2 = zeros(length(rmag.sample), 3);

for cnt = 1:length(calibrated_data2)
    % calibrated_data2(cnt, :) = rmag.sample(cnt, :) + bias;
    calibrated_data2(cnt, :) = rmag.sample(cnt, :)*calibrationMatrix + bias;
end

subplot(nRow, nCol, 4)
plot(calibrated_data2)
title('calibrated mag using formula (Estimated)')


figure(10)
clf

nCol = length(trial);
nRow = 3;

lResult = length(calibrated_data);
refMag = calibrated_data(1, :);
inferMag = zeros(lResult, 3);
diff = zeros(lResult, 3);

for t = 2:length(calibrated_data)
    eul = gyro.sample(t, :) * 1/rate;
    rotm = eul2rotm(eul, 'XYZ');

    inferMag(t, :) = (rotm\(refMag)')';
    diff(t, :) = calibrated_data(t, :) - inferMag(t, :);
    refMag = inferMag(t, :);
end

% diff for 2
lResult = length(calibrated_data2);
refMag = calibrated_data2(1, :);
inferMag = zeros(lResult, 3);
diff2 = zeros(lResult, 3);

for t = 2:length(calibrated_data2)
    eul = gyro.sample(t-1, :) * 1/rate;
    rotm = eul2rotm(eul, 'XYZ');

    inferMag(t, :) = (rotm\(refMag)')';
    diff2(t, :) = calibrated_data2(t, :) - inferMag(t, :);
    refMag = inferMag(t, :);
end

subplot(nRow, nCol, 1)
plot(mag.diff)
title('Naive features(diff)')

subplot(nRow, nCol, 2)
plot(diff)
title('Naive features(diff) using magcal')

subplot(nRow, nCol, 3)
plot(diff2)
title('Naive features(diff) using formula')

% figure(11)
% clf
% 
% nCol = length(trial);
% nRow = 3;
% 
% lResult = min([length(calibrated_data), length(mag.sample)]);
% diffMagcal = zeros(lResult, 3);
% 
% for cnt = 1:length(diffMagcal)
%     diffMagcal(cnt, :) = mag.sample(cnt, :) - calibrated_data(cnt, :);
% end
% 
% lResult = min([length(calibrated_data2), length(mag.sample)]);
% diffFormula = zeros(lResult, 3);
% 
% for cnt = 1:length(diffFormula)
%     diffFormula(cnt, :) = mag.sample(cnt, :) - calibrated_data2(cnt, :);
% end
% 
% subplot(nRow, nCol, 1)
% plot(diffMagcal)
% 
% subplot(nRow, nCol, 2)
% plot(diffFormula)