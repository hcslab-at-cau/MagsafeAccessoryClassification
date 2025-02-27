%% Ground truth
features = struct();
usingDetection = true;

for cnt = 1:length(ori)
    features(cnt).name = ori(cnt).name;
    features(cnt).feature = [];
    features(cnt).attach = [];
    features(cnt).detach = [];
    
    for cnt2 = 1:length(ori(cnt).trial)
        cur = ori(cnt).trial(cnt2);
        gyro = cur.gyro;
        mag = cur.rmag;
        acc = cur.acc;
        detect = cur.detect.sample;

        [calm, bias, ~] = magcal(mag.sample(1:500, :));
        mag.calibrated = (mag.sample-bias)*calm;
        

        % if cnt2 > 6
        %     continue
        % end
        
        if usingDetection
            gyro.raw = gyro.sample;
            [gyro.q, gyro.cumQ] = func_quat_from_gyro(gyro.sample, params.data.rate);
  
            [mag.diff, mag.inferred, mag.magnitude, mag.rmOri] = func_calc_diff(mag.calibrated, gyro.q, params);
            mag.mean = movmean(mag.diff, params.pre.movWinSize);
    
            % Extract the magnitude of high-pass filtered samples  
            % mag.magnitude = sqrt(sum(filtfilt(params.pre.fHB, params.pre.fHA, mag.calibrated).^2, 2));
            acc.magnitude = sqrt(sum(filtfilt(params.pre.fHBAcc, params.pre.fHAAcc, acc.sample).^2, 2));    

            detected = func_detect_events(mag, acc, params);
            detected = find(detected.all);
        end

        for cnt3 = 1:1:length(detect)
            pnt = detect(cnt3);
            
            if usingDetection == true
                idx = detected(detected > pnt-300 & detected <= pnt);

                if ~isempty(idx)
                    if length(idx) ~= 1
                        idx = idx(end);
                    end
    
                    bias = [0, 0, 0];
                    
                    if mod(cnt3, 2 == 0) && diff(2) == 0
                        continue
                    end

                    if mod(cnt3, 2) == 0
                        bias = diff;
                    end
                    
                    diff = func_compute_bias_margin(mag, gyro, bias, idx, params,  ...
                        params.identify.prc, true,  mod(cnt3, 2) == 1);
                    
                    if mod(cnt3, 2) == 0
                        diff = -diff;
                    end
                    
                    if mod(cnt3, 2) == 1
                        features(cnt).attach = [features(cnt).attach;diff];
                        bias = diff;
                    else
                        features(cnt).detach = [features(cnt).detach;diff];
                        bias = [0, 0, 0];
                    end
                  
                    features(cnt).feature = [features(cnt).feature; diff];

                    
                    mag = func_update_diff(mag, gyro.q, params, attached.bias, pnt);
                    mag.mean = movmean(mag.diff, params.pre.movWinSize);

                    detected = func_detect_events(mag, acc, params);
                    detected = find(detected.all);    
                end
            else
                interval = 1;

                if mod(cnt3, 2) == 1
                    s = pnt-150;
                    e = pnt+150;

                    refMag = mag.calibrated(s-1, :);
                else
                    e = pnt-400;
                    s = pnt;
                    
                    interval = -interval;

                    refMag = mag.calibrated(s+1, :);
                end

                for cnt4 = s:interval:e
                    euler = gyro.sample(cnt4, :) * 0.01;
                    rotm = eul2rotm(euler, 'XYZ');

                    refMag = (rotm\(refMag)')';
                end

                diff = mag.calibrated(e, :) - refMag;

                
                features(cnt).feature = [features(cnt).feature;diff];
            end
        end
    end

    % features(cnt).feature = rmoutliers(features(cnt).feature, 'percentiles', [1 99]);
    % features(cnt).feature = features(cnt).feature;

    disp([features(cnt).name, ' length : ', num2str(length(features(cnt).feature))])
end

chargingAcc = {'charger1', 'charger2', 'charger3', 'holder2', 'holder4', 'batterypack1'};
all = {features.name};

% except = {'cooler'};
% features(ismember(all, except)) = [];

% select = all(~ismember(all, chargingAcc));
all = {'charger2', 'charger3'};
select = all;
func_plot_scatter(features, select)

return;
%% Rotation Feature extraction
interval = 10;

features = struct();

% except = {'griptok1', 'holder5'};
% nOri = ori(~ismember({ori.name}, except));
nOri = ori;

for cnt = 1:length(nOri)
    features(cnt).name = nOri(cnt).name;
    features(cnt).feature = [];
    diff = [];

    % for cnt2 = 1:length(ori(cnt).trial)
    for cnt2 = 1
        cur = nOri(cnt).trial(cnt2);
        detect = cur.detect.sample;
        varThreshold = 0.5;

        if length(detect) < 2
            continue
        end
        mag = cur.rmag;
        gyro = cur.gyro;
        
        [calm, bias, ~ ] = magcal(mag.sample(1:500, :));
        mag.sample = (mag.sample-bias)*calm;
        
        [gyro.q, gyro.cumQ] = func_quat_from_gyro(gyro.sample, 100);
        
        % Margin
        front = detect(1) + 100;
        last = detect(2) - 200;
        
        refMag = mag.sample(detect(1)-200, :);
        refs = quatrotate(quatinv(gyro.cumQ(detect(1)-200, :)), refMag);

        for cnt3 = front:last
            rotated = quatrotate(gyro.cumQ(cnt3, :), refs);
            diff = [diff; mag.sample(cnt3, :) - rotated];
        end

        diff = diff(1:2:length(diff), :);
        filtered = [];

        while length(filtered) > 300 || length(filtered) < 250
            for cnt3 = interval + 1:length(diff) - interval
                range = cnt3 + (-interval:interval);
    
                v = var(diff(range, :));
                
                if rssq(v) > varThreshold
                    filtered(end + 1, :) = diff(cnt3, :);
                end
            end

            % disp([num2str(length(filtered)), '-', num2str(varThreshold)])

            if length(filtered) < 250
                varThreshold = varThreshold / 2;
                filtered = [];
            elseif length(filtered) > 300
                varThreshold = varThreshold * 3;
                filtered = [];
            end
        end
        features(cnt).feature = [features(cnt).feature;filtered];
    end
    
    disp([features(cnt).name,' Diff length : ', num2str(length(diff)), ', Filtered length : ', num2str(length(features(cnt).feature))])

    features(cnt).diff = diff;
    
end

func_plot_scatter(features, {features.name})
%%
a = load('templates/reference.mat');
a = a.feature;

select = {'charger1', 'charger2', 'charger3', 'holder2', 'holder4', 'batterypack1'};

% a = a(ismember({a.name}, select));

func_plot_scatter(a, {a.name})
%% To Merge feature

a = load('templates/wallet2.mat');
a = a.feature;

a = a(find(ismember({a.name}, 'wallet2')));

b = load('templates/reference.mat');
b = b.feature;
% nOri = struct();

% l = 30;
% % If need to adjust length of features
% for cnt = 1:length(b)
%     b(cnt).feature = b(cnt).feature(1:30, :);
% end


for cnt = 1:length(a)
    idx = find(ismember({b.name}, a(cnt).name));

    if ~isempty(idx)
        % b(idx).feature = [b(idx).feature;a(cnt).feature];
        b(idx).feature = a(cnt).feature;
    else
        % b(end + 1).feature = a(cnt).feature;
        % b(end).name = a(cnt).name;
    end
end

features = b;

func_plot_scatter(features, {features.name})
%%
a = load('features/ref_orientation3_all.mat');
a = a.feature;

for cnt = 1:length(a)
    a(cnt).feature = a(cnt).feature;
    
end


%%
oriented = load('features/ref_orientation2.mat');
oriented = load('templates/reference.mat');
oriented = oriented.feature;

% for cnt = 1:length(oriented)
%     oriented(cnt).feature = oriented(cnt).filtered;
% end

func_plot_scatter(oriented, {oriented.name})
%%

oriented = load('features/ref_orientation3.mat');
oriented = oriented.feature;

ori = load('features/ref1_1_99.mat');
ori = ori.feature;
% nOri = struct();

for cnt = 1:length(oriented)
    % nOri(cnt).name = oriented(cnt).name;
    % nOri(cnt).feature = oriented(cnt).filtered;
    idx = find(ismember({ori.name}, oriented(cnt).name));

    if ~isempty(idx)
        % ori(idx).feature = [ori(idx).feature;oriented(cnt).filtered];
        ori(idx).feature =oriented(cnt).filtered;
    end
end

feature = ori;
% save(['./features/', 'ref1_o3.mat'], 'feature')
%% 
feature = features;
save(['./templates/', 'orientation2'], 'feature')