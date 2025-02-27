%% Extract features used for detection
% Filter parameters for magnetometer


feature = struct();
for cnt = 1:params.data.nObjects
    for cnt2 = 1:length(data(cnt).trial)
        for cnt3 = 1:length(params.data.sensors)
            sensor = char(params.data.sensors(cnt3));

            sample = data(cnt).trial(cnt2).(sensor).sample;
            cur = struct();

            switch sensor                
                case 'gyro' % Obtain quaternions 
                    cur.raw = sample;
                    cur.magnitude = sum(filtfilt(params.pre.fHBAcc, params.pre.fHAAcc, sample).^2, 2);   
                    [cur.q, cur.cumQ] = func_quat_from_gyro(sample, params.data.rate);
                                     
                case {'mag', 'rmag'} 
                    % Do calication
                    [cur.raw, cur.calibrated, cur.A, cur.B] = ...
                        func_calib_mag(sample, data(cnt).trial(cnt2).(sensor).calSample, strcmp(sensor, 'rmag'));
                    
                    if params.data.pre && strcmp(sensor, 'rmag')
                        cur.calibrated = (sample-params.pre.bias)*params.pre.calm;
                        cur.raw = sample;
                        cur.A = params.pre.calm;
                        cur.B = params.pre.bias;
                    end

                    % Compare the calibrated samples and the inferred samples
                    [cur.diff, cur.inferred, cur.magnitude, cur.rmOri] = func_calc_diff(cur.calibrated, feature(cnt).trial(cnt2).gyro.q, params);

                    cur.mean = movmean(cur.diff, params.pre.movWinSize);

                    % Extract the magnitude of high-pass filtered samples  
                    % cur.magnitude = sqrt(sum(filtfilt(params.pre.fHB, params.pre.fHA, cur.calibrated).^2, 2));   
                case 'acc'
                    cur.raw = sample;
                    
                    cur.magnitude = sqrt(sum(filtfilt(params.pre.fHBAcc, params.pre.fHAAcc, sample).^2, 2));    
            end
            
            feature(cnt).trial(cnt2).(sensor) = cur;
        end
        feature(cnt).name = data(cnt).name;
        feature(cnt).trial(cnt2).event = data(cnt).trial(cnt2).event;
    end
end