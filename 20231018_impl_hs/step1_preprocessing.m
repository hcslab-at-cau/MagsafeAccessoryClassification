%% Extract features used for detection
tic
% Filter parameters for magnetometer
params.pre.fOrder = 4;
params.pre.fHCut = 10;
params.pre.fLCut = 2.5;
params.pre.movWinSize = params.data.rate * .4;

[params.pre.fHB, params.pre.fHA] = butter(params.pre.fOrder, ...
    params.pre.fHCut/params.data.rate * 2, 'high');

[params.pre.fLB, params.pre.fLA] = butter(params.pre.fOrder, ...
    params.pre.fLCut/params.data.rate * 2, 'low');

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
                    [cur.q, cur.cumQ] = func_quat_from_gyro(sample, params.data.rate);
                                        
                case {'mag', 'rmag'} 
                    % Do calication
                    [cur.raw, cur.calibrated, cur.A, cur.B] = ...
                        func_calib_mag(sample, strcmp(sensor, 'rmag'), params.pre.cRange);
                    
                    % Compare the calibrated samples and the inferred samples
                    [cur.diff, cur.inferred] = func_calc_diff(cur.calibrated, feature(cnt).trial(cnt2).gyro.q);
%                     cur.lpf = filtfilt(params.pre.fLB, params.pre.fLA, cur.diff);
                    cur.mean = movmean(cur.diff, params.pre.movWinSize);

                    % Extract the magnitude of high-pass filtered samples  
                    cur.magnitude = sqrt(sum(filtfilt(params.pre.fHB, params.pre.fHA, cur.calibrated).^2, 2));                     
            end
            
            if params.data.newApp == false
                cur.rmag = cur.mag;
            end

            feature(cnt).trial(cnt2).(sensor) = cur;
        end

    end
end
toc