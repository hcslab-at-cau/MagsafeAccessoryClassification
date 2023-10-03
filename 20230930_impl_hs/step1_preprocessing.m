tic
% Filter parameters for magnetometer
params.pre.fOrder = 4;
params.pre.fCut = 10;

[params.pre.fB, params.pre.fA] = butter(params.pre.fOrder, ...
    params.pre.fCut/params.data.rate * 2, 'high');

params.pre.cRange = 1:params.data.rate * 5; % For raw magnetometer calibration

for cnt = 1:length(data)
    for cnt2 = 1:length(data(cnt).trial)
        for cnt3 = 1:length(params.data.sensors)
            sensor = char(params.data.sensors(cnt3));
            cur = data(cnt).trial(cnt2).(sensor);
            
            switch sensor                
                case 'gyro'                    
                    cur.q = func_quat_from_gyro(cur.sample, params.data.rate);
                                        
                case {'mag', 'rmag'}
                    [cur.raw, cur.calibrated, cur.A, cur.B] = ...
                        func_calib_mag(cur.sample, strcmp(sensor, 'rmag'), params.pre.cRange);
                    
                    [cur.diff, cur.inferred] = func_calc_diff(cur.calibrated, data(cnt).trial(cnt2).gyro.q);

                    cur.magnitude = sqrt(sum(filtfilt(params.pre.fB, params.pre.fA, ...
                        cur.sample).^2, 2)); % Extract the magnitude of high-pass filtered samples  
            end
            
            data(cnt).trial(cnt2).(sensor) = cur;
        end
    end
end

feature = struct();
for cnt = 1:length(data)
    for cnt2 = 1:length(data(cnt).trial)
        if params.data.newApp == true
            mag = data(cnt).trial(cnt2).rmag;
        else
            mag = data(cnt).trial(cnt2).mag;
        end

        idx = 1;
        feature(cnt).trial(cnt2).ref = zeros(length(ref) * params.ref.nSub + 1, length(mag.raw));
        for cnt3 = 1:length(ref)
            for cnt4 = 1:params.ref.nSub
                calibrated = (mag.raw - ref(cnt3).feature(cnt4, :) - mag.B) * mag.A;
                feature(cnt).trial(cnt2).ref(idx, :) = ...
                    func_calc_diff(calibrated, data(cnt).trial(cnt2).gyro.q);
                idx = idx + 1;
            end
        end
        feature(cnt).trial(cnt2).ref(end, :) = mag.diff;
    end
end
toc