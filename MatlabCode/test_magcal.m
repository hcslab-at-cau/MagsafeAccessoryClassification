accId = 1;
trial = 1;

tmp = data(accId).trial(trial);
mag = tmp.mag;
rmag = tmp.rmag;
range = 1:50;

figure(9)
clf

nCol = length(trial);
nRow = 5;

subplot(nRow, nCol, 1)
plot(mag.diff)
title('diff')

subplot(nRow, nCol, 2)
plot(rmag.sample)
title('raw mag values')

subplot(nRow, nCol, 3)
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
    % calibrated_data(cnt, :) = (rmag.sample(cnt, :) - b)*A;
    calibrated_data(cnt, :) = rmag.sample(cnt, :)*A + bias;
end

subplot(nRow, nCol, 4)
plot(calibrated_data)
title('calibrated mag using magcal (Estimated)')


% Magnetometer bias calculation using equation
% Calibration_data = Raw_data * calibration_matrix + bias
% = Raw_data * matrix
rRange = range;
rawData = rmag.sample(rRange, :);
calibratedData = mag.sample(1:50, :);
rawDatas = [rawData, ones(size(rawData, 1), 1)];
matrix = rawDatas \ calibratedData;

% Now, calibration_parameters is a 4x3 matrix. The first three rows are the calibration matrix,
% and the last row is the bias vector.
calibrationMatrix = matrix(1:3, :);
bias = matrix(4, :);

calibrated_data = zeros(length(rmag.sample), 3);

for cnt = 1:length(calibrated_data)
    calibrated_data(cnt, :) = rmag.sample(cnt, :)*calibrationMatrix + bias;
end

subplot(nRow, nCol, 5)
plot(calibrated_data)
title('calibrated mag using formula (Estimated)')