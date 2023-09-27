tic
% Filter parameters for magnetometer & accelerometer
params.pre.fOrder = 4;
params.pre.fMag = 10;
params.pre.fAcc = 40;

[filters.mag.b, filters.mag.a] = butter(params.pre.fOrder, ...
    params.pre.fMag/params.data.rate * 2, 'high');

filters.acc.f = 40;
[filters.acc.b, filters.acc.a] = butter(params.pre.fOrder, ...
    params.pre.fAcc/params.data.rate * 2, 'high');

params.pre.cRange = 1:params.data.rate * 5; % For raw magnetometer calibration

parfor cnt = 1:length(data)
    for cnt2 = 1:length(data(cnt).trial)
        for cnt3 = 1:length(params.data.sensors)
            sensor = char(params.data.sensors(cnt3));
            cur = data(cnt).trial(cnt2).(sensor);
            
            switch sensor                
                case 'gyro'
                    cur.dAngle = sqrt(sum(cur.sample.^2, 2)) / params.data.rate;
                    
                    cur.q = zeros(length(cur.sample), 4);
                    for cnt4 = 2:length(cur.sample)
                        theta = (1/params.data.rate) * norm(cur.sample(cnt4, :));
                        v = cur.sample(cnt4, :) / norm(cur.sample(cnt4, :)) * sin(theta/2);
                        q = quaternion(cos(theta/2), v(1), v(2), v(3)); 
                        
                        cur.q(cnt4, :) = q.compact();
                    end
                    
                case 'acc'
                    cur.magnitude = sum(filtfilt(filters.acc.b, filters.acc.a, cur.sample).^2, 2);
                    
                case {'mag', 'rmag'}
                    if strcmp(sensor, 'rmag') == true
                        cur.raw = cur.sample;

                        [cur.A, cur.B, ~] = magcal(cur.raw(params.pre.cRange, :));
                        cur.sample = (cur.raw - cur.B) * cur.A;                        
                    end                    
                    
                    gyro = data(cnt).trial(cnt2).gyro;
                    
                    cur.dAngle = zeros(length(cur.sample), 1);
                    cur.inferred = cur.sample;                    
                    
                    for cnt4 = 2:length(cur.sample)
                        cur.dAngle(cnt4) = subspace(cur.sample(cnt4, :)', cur.sample(cnt4 - 1, :)');                        
                        cur.inferred(cnt4, :) = quatrotate(gyro.q(cnt4, :), cur.sample(cnt4 - 1, :));
                    end                       
                    cur.diff = abs(cur.inferred - cur.sample);
                    
                    cur.magnitude = sum(filtfilt(filters.mag.b, filters.mag.a, cur.sample).^2, 2); % Extract the magnitude of high-pass filtered samples  
            end
            
            data(cnt).trial(cnt2).(sensor) = cur;
        end
    end
end
toc




% parfor cnt = 1:length(data)
%     nTrials = length(data(cnt).trial);
%     
%     for cnt2 = 1:nTrials
%         for cnt3 = 1:length(sensors)
%             cur = data(cnt).trial(cnt2).(char(sensors(cnt3)));
% 
%             switch char(sensors(cnt3))
%                 case 'gyro' % Extract the amount of schanges in angle
%                     cur.dAngle = sqrt(sum(cur.sample.^2, 2)) * 1/rate;  
% 
%                 case 'acc' % Extract the magnitude of high-pass filtered samples         
%                     cur.magnitude = sum(filtfilt(b.acc, a.acc, cur.sample).^2, 2);     
% 
%                 case 'mag' 
%                     cur.dAngle = zeros(length(cur.sample), 1); % Extract the amount of changes in angle
%                     for cnt4 = 2:length(cur.sample)
%                         cur.dAngle(cnt4) = subspace(cur.sample(cnt4, :)', cur.sample(cnt4 - 1, :)');
%                     end                       
%                     cur.magnitude = sum(filtfilt(b.mag, a.mag, cur.sample).^2, 2); % Extract the magnitude of high-pass filtered samples  
% 
%                 case 'rmag'
%                     cur.rawSample = cur.sample;
%                     [calibrationMatrix, bias, expmfs] = magcal(cur.sample(calibrationRange, :));
% 
%                     cur.dAngle = zeros(length(cur.sample), 1); % Extract the amount of changes in angle
% 
%                     % Calibrate raw magnetometer value
%                     cur.sample = (cur.rawSample - bias) * calibrationMatrix; 
% 
%                     for cnt4 = 2:length(cur.sample)
%                         cur.dAngle(cnt4) = subspace(cur.sample(cnt4, :)', cur.sample(cnt4 - 1, :)');
%                     end
% 
%                     cur.magnitude = sum(filtfilt(b.mag, a.mag, cur.sample).^2, 2); % Extract the magnitude of high-pass filtered samples  
%             end
% 
%             data(cnt).trial(cnt2).(char(sensors(cnt3))) = cur;
%         end
% 
%         % For calibrated magnetometer preprocess
%         magType = {'mag'};
%         if newApp == true
%             magType = [magType; 'rmag'];
%         end
%                
%         gyro = data(cnt).trial(cnt2).('gyro');
%         
%         for cnt3 = 1:length(magType)
%             mag = data(cnt).trial(cnt2).(char(magType(cnt3)));
%             
%             
%             
%         end
%         
% %         for i = 1:length(magType)
% %             mag = data(cnt).trial(cnt2).(char(magType(i)));
% %             lResult = min([length(gyro.sample), length(mag.sample)]);
% %             refMag = mag.sample(1, :);
% %     
% %             inferMag = zeros(lResult, 3);
% %             inferMag1s = zeros(lResult, 3);
% %             diff = zeros(lResult, 3);
% %             diffSum = zeros(lResult, 1);
% %             inferAngle = zeros(lResult, 1);
% %             corrData = zeros(2, lResult);
% %             q = zeros(lResult, 4);
% %     
% %             for t = 2:lResult
% %                 theta = (1/rate) * norm(gyro.sample(t, :));
% %                 v = gyro.sample(t, :) / norm(gyro.sample(t, :)) * sin(theta/2);                
% %                 tmp = quaternion(cos(theta/2), v(1), v(2), v(3));
% %                 q(t, :) = tmp.compact;
% %                 
% %                 inferMag1s(t, :) = quatrotate(q(t, :), mag.sample(t-1, :));
% %                 
% %                 if t > 2
% %                     tmp = prevq * tmp;
% %                 end
% %                 prevq = tmp;
% %                     
% %                 inferMag(t, :) = quatrotate(prevq.compact, refMag);
% %                 
% %                                 
% %                 % infer Angle --> angle between inferred mag and real mag
% %                 % inferred mag --> using prev 0.01s mag and gyroscope.
% %                 inferAngle(t) = subspace(inferMag1s(t, :)', mag.sample(t, :)');                
% %     
% %                 diff(t, :) = mag.sample(t, :) - inferMag1s(t, :);
% %                 diffSum(t) = sqrt(sum(power(diff(t, :), 2)));
% %             end
% %             interval = 5;
% %     
% %             for t = interval + 1:lResult-interval
% %                 range = t + (-interval:interval);
% %                 corrData(1, t) = corr(mag.dAngle(range), inferAngle(range));
% %                 corrData(2, t) = corr(mag.dAngle(range), gyro.dAngle(range));
% %             end
% % 
% %             mag.diff= diff;
% %             mag.inferAngle = inferAngle;
% %             mag.diffSum = diffSum;
% %             mag.corrData = corrData;
% %             mag.inferMag = inferMag;
% %             mag.inferMag1s = inferMag1s
% %             mag.q = q;
% %             
% %             data(cnt).trial(cnt2).(char(magType(i))) = mag;
% %         end
%     end
% end
% toc