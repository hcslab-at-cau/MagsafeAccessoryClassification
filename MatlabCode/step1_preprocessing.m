tic
if newApp == true
    run("step1_timestamp_preprocessing.m")
end

% Parameters
sensors = {'gyro', 'mag', 'acc'};

if newApp == true
    sensors = [sensors, 'rmag'];
end

% Filter parameters for magnetometer
rate = 100;
order = 4;
[b.mag, a.mag] = butter(order, 10/rate * 2, 'high');

wSize = 1 * rate;
calibrationRange = (1:200); % For raw magnetometer calibration

% Filter parameters for accelerometer 
[b.acc, a.acc] = butter(order, 40/rate * 2, 'high');

for cnt = 1:length(data)
    nTrials = length(data(cnt).trial);
    
    for cnt2 = 1:nTrials
        for cnt3 = 1:length(sensors)
            cur = data(cnt).trial(cnt2).(char(sensors(cnt3)));

            switch char(sensors(cnt3))
                case 'gyro' % Extract the amount of schanges in angle
                    cur.dAngle = sqrt(sum(cur.sample.^2, 2)) * 1/rate;  

                case 'acc' % Extract the magnitude of high-pass filtered samples         
                    cur.magnitude = sum(filtfilt(b.acc, a.acc, cur.sample).^2, 2);     

                case 'mag' 
                    cur.dAngle = zeros(length(cur.sample), 1); % Extract the amount of changes in angle
                    for cnt4 = 2:length(cur.sample)
                        cur.dAngle(cnt4) = subspace(cur.sample(cnt4, :)', cur.sample(cnt4 - 1, :)');
                    end                       
                    cur.magnitude = sum(filtfilt(b.mag, a.mag, cur.sample).^2, 2); % Extract the magnitude of high-pass filtered samples  

                case 'rmag'
                    cur.rawSample = cur.sample;
                    [calibrationMatrix, bias, expmfs] = magcal(cur.sample(calibrationRange, :));

                    cur.dAngle = zeros(length(cur.sample), 1); % Extract the amount of changes in angle

                    % Calibrate raw magnetometer value
                    cur.sample(1, :) = (cur.sample(1, :) - bias) * calibrationMatrix; 
                    % cur.sample(1, :) = (cur.sample(1, :) - bias);
                    for cnt4 = 2:length(cur.sample)
                        cur.sample(cnt4, :) = (cur.sample(cnt4, :) - bias) * calibrationMatrix;
                        % cur.sample(cnt4, :) = (cur.sample(cnt4, :) - bias);
                        cur.dAngle(cnt4) = subspace(cur.sample(cnt4, :)', cur.sample(cnt4 - 1, :)');
                    end

                    cur.magnitude = sum(filtfilt(b.mag, a.mag, cur.sample).^2, 2); % Extract the magnitude of high-pass filtered samples  
            end

            data(cnt).trial(cnt2).(char(sensors(cnt3))) = cur;
        end

        % For calibrated magnetometer preprocess
        magType = {'mag'};
        if newApp == true
            magType = [magType; 'rmag'];
        end

        gyro = data(cnt).trial(cnt2).('gyro');
    
        for i = 1:length(magType)
            mag = data(cnt).trial(cnt2).(char(magType(i)));
            lResult = min([length(gyro.sample), length(mag.sample)]);
            refMag = mag.sample(1, :);
    
            inferMag = zeros(lResult, 3);
            inferMag1s = zeros(lResult, 3);
            diff = zeros(lResult, 3);
            diffSum = zeros(lResult, 1);
            inferAngle = zeros(lResult, 1);
            corrData = zeros(2, lResult);
    
            for t = 2:lResult
                euler = gyro.sample(t, :) * 1/rate;
                rotm = eul2rotm(euler, 'XYZ');
                inferMag(t, :) = (rotm \ (refMag)')';
                inferMag1s(t, :) = (rotm\(mag.sample(t-1, :))')';
                
                % infer Angle --> angle between inferred mag and real mag
                % inferred mag --> using prev 0.01s mag and gyroscope.
                inferAngle(t) = subspace(inferMag1s(t, :)', mag.sample(t, :)');
                refMag = inferMag(t, :);
    
                diff(t, :) = mag.sample(t, :) - inferMag(t, :);
                diffSum(t) = sqrt(sum(power(diff(t, :), 2)));
            end
            interval = 5;
    
            for t = interval + 1:lResult-interval
                range = t + (-interval:interval);
                corrData(1, t) = corr(mag.dAngle(range), inferAngle(range));
                corrData(2, t) = corr(mag.dAngle(range), gyro.dAngle(range));
            end

            mag.diff= diff;
            mag.inferAngle = inferAngle;
            mag.diffSum = diffSum;
            mag.corrData = corrData;
            mag.inferMag = inferMag;
            
            data(cnt).trial(cnt2).(char(magType(i))) = mag;
        end
    end
end
toc

% figure(1)
% clf
% accId = 1;
% nRow = 3;
% nCol = 5;
% 
% for cnt = 1:4
%     cur = data(accId).trial(cnt);
% 
%     subplot(nRow, nCol, cnt)
%     hold on
%     plot(cur.gyro.dAngle)
%     plot(cur.mag.dAngle)
%     title('Delta angle (rads)')
%     legend({'gyro', 'mag'})
% 
%     subplot(nRow, nCol, nCol + cnt)
%     plot(cur.mag.magnitude)    
%     title('HPF (10Hz) magnitude')
%     legend('mag (after HPF)')
% 
%     subplot(nRow, nCol, 2 * nCol + cnt)
%     plot(cur.acc.magnitude)    
%     title('HPF (40Hz) magnitude')
%     legend('acc (after HPF)')
% end