% Parameters
sensors = {'gyro', 'mag', 'acc'};

% Filter parameters for magnetometer
rate = 100;
order = 4;
[b.mag, a.mag] = butter(order, 10/rate * 2, 'high');

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
                    
                case 'mag' 
                    cur.dAngle = zeros(length(cur.sample), 1); % Extract the amount of changes in angle
                    for cnt4 = 2:length(cur.sample)
                        cur.dAngle(cnt4) = subspace(cur.sample(cnt4, :)', cur.sample(cnt4 - 1, :)');
                    end                       
                    cur.magnitude = sum(filtfilt(b.mag, a.mag, cur.sample).^2, 2); % Extract the magnitude of high-pass filtered samples  
            end

            data(cnt).trial(cnt2).(char(sensors(cnt3))) = cur;
        end

        % Infer Magnetometer using gyroscope
        mag = data(cnt).trial(cnt2).('mag');
        gyro = data(cnt).trial(cnt2).('gyro').sample;
        
        lResult = min([length(gyro), length(mag.sample)]);
        refMag = mag.sample(1, :);
        
        mag.inferMag = zeros(lResult, 3);
        mag.diff = zeros(lResult, 3);
            
        for t = 2:lResult
            euler = gyro(t, :) * 1/rate;
            rotm = eul2rotm(euler, 'XYZ');
            mag.inferMag(t, :) = (rotm \ (refMag)')';
            mag.refInferMag(t, :) = (rotm\(mag.sample(t-1, :))')';
            refMag = mag.inferMag(t, :);

            mag.diff(t, :) = mag.sample(t, :) - mag.inferMag(t, :);
        end

        data(cnt).trial(cnt2).('mag') = mag;
    end
end
 
figure(1)
clf
accId = 1;
nRow = 3;
nCol = 5;

for cnt = 1:5
    cur = data(accId).trial(cnt);
    
    subplot(nRow, nCol, cnt)
    hold on
    plot(cur.gyro.dAngle)
    plot(cur.mag.dAngle)
    title('Delta angle (rads)')
    legend({'gyro', 'mag'})
    
    subplot(nRow, nCol, nCol + cnt)
    plot(cur.mag.magnitude)    
    title('HPF (10Hz) magnitude')
    legend('mag (after HPF)')
    
    subplot(nRow, nCol, 2 * nCol + cnt)
    plot(cur.acc.magnitude)    
    title('HPF (40Hz) magnitude')
    legend('acc (after HPF)')
end