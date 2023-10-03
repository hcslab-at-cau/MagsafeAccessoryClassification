tic
% Filter parameters for magnetometer & accelerometer
params.pre.fOrder = 4;
params.pre.fCut = 10;

[filters.b, filters.a] = butter(params.pre.fOrder, ...
    params.pre.fCut/params.data.rate * 2, 'high');

params.pre.cRange = 1:params.data.rate * 5; % For raw magnetometer calibration

parfor cnt = 1:length(data)
    for cnt2 = 1:length(data(cnt).trial)
        for cnt3 = 1:length(params.data.sensors)
            sensor = char(params.data.sensors(cnt3));
            cur = data(cnt).trial(cnt2).(sensor);
            
            switch sensor                
                case 'gyro'                    
                    cur.q = zeros(length(cur.sample), 4);
                    for cnt4 = 2:length(cur.sample)
                        theta = (1/params.data.rate) * norm(cur.sample(cnt4, :));
                        v = cur.sample(cnt4, :) / norm(cur.sample(cnt4, :)) * sin(theta/2);
                        q = quaternion(cos(theta/2), v(1), v(2), v(3)); 
                        
                        cur.q(cnt4, :) = q.compact();
                    end
                    
                case 'acc'
                    
                case {'mag', 'rmag'}
                    cur.raw = cur.sample;
                    if strcmp(sensor, 'rmag') == true
                        cur.raw = cur.sample;

                        [cur.A, cur.B, ~] = magcal(cur.raw(params.pre.cRange, :));
                        cur.sample = (cur.raw - cur.B) * cur.A;  
                    else
                        cur.A = 1;
                        cur.B = 0;
                    end                    
                    
                    gyro = data(cnt).trial(cnt2).gyro;
                    
                    cur.inferred = [cur.sample(1, :); ...
                        quatrotate(gyro.q(2:end, :), cur.sample(1:end - 1, :))];              
                    cur.diff = abs(cur.inferred - cur.sample);
                    
                    cur.magnitude = sum(filtfilt(filters.b, filters.a, cur.sample).^2, 2); % Extract the magnitude of high-pass filtered samples  
            end
            
            data(cnt).trial(cnt2).(sensor) = cur;
        end
    end
end
toc