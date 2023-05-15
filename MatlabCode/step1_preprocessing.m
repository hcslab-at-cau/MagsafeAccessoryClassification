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

        magData = data(cnt).trial(cnt2).('mag');
        gyroData = data(cnt).trial(cnt2).('gyro').sample;
        acc = data(cnt).trial(cnt2).('acc');
        
        l = min([length(gyroData), length(magData.sample), length(acc.sample)]);
        refMag = magData.sample(1, :);
        
        magData.inferMag = zeros(l, 3);
            
        for t = 2:l
            euler = gyroData(t, :) * 1/rate;
            rotm = eul2rotm(euler, 'XYZ');
            magData.inferMag(t, :) = (rotm \ (refMag)')';
            magData.refInferMag(t, :) = (rotm\(magData.sample(t-1, :))')';
            refMag = magData.inferMag(t, :);

            %rotMat = mag.sample()
        end

        diff = zeros(length(l), 3);

    
        for t = 1:l-1
            diff(t, :) = magData.sample(t, :) - magData.inferMag(t, :);
        end
        
        acc.cfarData = zeros(1, l);
        magData.cfarData = zeros(1, l);

        for cnt3 = wSize + 1:l
            range = cnt3 + (-wSize:-1);
            
            magData.cfarData(cnt3) = func_CFAR(magData.magnitude(range), ...
                magData.magnitude(cnt3), 0.9999);

            acc.cfarData(cnt3) = func_CFAR(acc.magnitude(range), ...
                acc.magnitude(cnt3), 0.9999);
        end
        
        magData.diff = diff;
        data(cnt).trial(cnt2).('mag') = magData;
        data(cnt).trial(cnt2).('acc') = acc;
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