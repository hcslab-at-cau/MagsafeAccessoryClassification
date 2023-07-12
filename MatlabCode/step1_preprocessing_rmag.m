% Parameters
sensors = {'gyro', 'rmag', 'acc'};


% Filter parameters for magnetometer
rate = 100;
order = 4;
[b.rmag, a.rmag] = butter(order, 10/rate * 2, 'high');

wSize = 1 * rate;

% Filter parameters for accelerometer 
[b.acc, a.acc] = butter(order, 40/rate * 2, 'high');

for cnt = 1:length(data)
    nTrials = length(data(cnt).trial);
    
    for cnt2 = 1:nTrials
        for cnt3 = 1:length(sensors)
            cur = data(cnt).trial(cnt2).(char(sensors(cnt3)));

            switch char(sensors(cnt3))
                case 'gyro' % Extract the amount of changes in angle
                    cur.dAngle = sqrt(sum(cur.sample.^2, 2)) * 1/rate;  

                case 'acc' % Extract the magnitude of high-pass filtered samples         
                    cur.magnitude = sum(filtfilt(b.acc, a.acc, cur.sample).^2, 2);     

                case 'rmag'
                    [A, bias, expmfs] = magcal(cur.sample(1:200, :));

                    cur.dAngle = zeros(length(cur.sample), 1); % Extract the amount of changes in angle

                    % Calibrate raw magnetometer value
                    cur.sample(1, :) = (cur.sample(1, :) - bias) * A; 
                    for cnt4 = 2:length(cur.sample)
                        cur.sample(cnt4, :) = (cur.sample(cnt4, :) - bias) * A;
                        cur.dAngle(cnt4) = subspace(cur.sample(cnt4, :)', cur.sample(cnt4 - 1, :)');
                    end

                    cur.magnitude = sum(filtfilt(b.rmag, a.rmag, cur.sample).^2, 2); % Extract the magnitude of high-pass filtered samples  
            end

            data(cnt).trial(cnt2).(char(sensors(cnt3))) = cur;
        end

        % Infer Magnetometer using gyroscope
        rmag = data(cnt).trial(cnt2).('rmag');
        gyro = data(cnt).trial(cnt2).('gyro');

        lResult = min([length(gyro.sample), length(rmag.sample)]);
        refMag = rmag.sample(1, :);

        rmag.inferMag = zeros(lResult, 3);
        rmag.inferMag1s = zeros(lResult, 3);
        rmag.diff = zeros(lResult, 3);
        rmag.diffSum = zeros(lResult, 1);
        rmag.inferAngle = zeros(lResult, 1);
        corrData = zeros(2, lResult);

        for t = 2:lResult
            euler = gyro.sample(t, :) * 1/rate;
            rotm = eul2rotm(euler, 'XYZ');
            rmag.inferMag(t, :) = (rotm \ (refMag)')';
            rmag.inferMag1s(t, :) = (rotm\(rmag.sample(t-1, :))')';
            
            % infer Angle --> angle between inferred mag and real mag
            % inferred mag --> using prev 0.01s mag and gyroscope.
            rmag.inferAngle(t) = subspace(rmag.inferMag1s(t, :)', rmag.sample(t, :)');
            refMag = rmag.inferMag(t, :);

            rmag.diff(t, :) = rmag.sample(t, :) - rmag.inferMag(t, :);
            rmag.diffSum(t) = sqrt(sum(power(rmag.diff(t, :), 2)));
        end

        interval = 5;
        for t = interval + 1:lResult-interval
            range = t + (-interval:interval);
            corrData(1, t) = corr(rmag.dAngle(range), rmag.inferAngle(range));
            corrData(2, t) = corr(rmag.dAngle(range), gyro.dAngle(range));
        end
        
        data(cnt).trial(cnt2).corr = corrData;
        data(cnt).trial(cnt2).('rmag') = rmag;
    end
end