%% Extract features used for detection
tic
% Filter parameters for magnetometer
params.pre.fOrder = 4;
params.pre.fCut = 10;

[params.pre.fB, params.pre.fA] = butter(params.pre.fOrder, ...
    params.pre.fCut/params.data.rate * 2, 'high');

params.pre.cRange = 1:params.data.rate * 5; % For raw magnetometer calibration

feature = struct();
for cnt = 1:length(data)
    for cnt2 = 1:length(data(cnt).trial)
        for cnt3 = 1:length(params.data.sensors)
            sensor = char(params.data.sensors(cnt3));

            sample = data(cnt).trial(cnt2).(sensor).sample;
            cur = struct();

            switch sensor                
                case 'gyro' % Obtain quaternions 
                    cur.raw = sample;
                    cur.q = func_quat_from_gyro(sample, params.data.rate);
                                        
                case {'mag', 'rmag'} 
                    % Do calication
                    [cur.raw, cur.calibrated, cur.A, cur.B] = ...
                        func_calib_mag(sample, strcmp(sensor, 'rmag'), params.pre.cRange);
                    
                    % Compare the calibrated samples and the inferred samples
                    [cur.diff, cur.inferred] = func_calc_diff(cur.calibrated, feature(cnt).trial(cnt2).detect.gyro.q);

                    % Extract the magnitude of high-pass filtered samples  
                    cur.magnitude = sqrt(sum(filtfilt(params.pre.fB, params.pre.fA, sample).^2, 2)); 
            end
            
            if params.data.newApp == false
                cur.rmag = cur.mag;
            end

            feature(cnt).trial(cnt2).detect.(sensor) = cur;
        end

    end
end

%% Extract features used for identification
params.pre.mType = 'mag';

for cnt = 1:length(data)
    for cnt2 = 1:length(data(cnt).trial)
        mag = feature(cnt).trial(cnt2).detect.(params.pre.mType);

        idx = 1;
        feature(cnt).trial(cnt2).identify = zeros(length(ref) * params.ref.nSub + 1, length(mag.raw));
        for cnt3 = 1:length(ref)
            for cnt4 = 1:params.ref.nSub
                % Compute diff after calibrating with reference data
                calibrated = (mag.raw - ref(cnt3).feature(cnt4, :) - mag.B) * mag.A;
                feature(cnt).trial(cnt2).identify(idx, :) = ...
                    func_calc_diff(calibrated, feature(cnt).trial(cnt2).detect.gyro.q);
                idx = idx + 1;
            end
        end
        feature(cnt).trial(cnt2).identify(end, :) = mag.diff;
    end
end
toc