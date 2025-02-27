%% Figure for totally in 1
step0_parameter

accName = 'wallet2';
accId = find(ismember({ori.name}, accName));
trialId = 1;

cur = ori(accId).trial(trialId);
mag = cur.rmag;
gyro = cur.gyro;
acc = cur.acc;
event = cur.detect.sample;

% Preprocessing gyro
gyro.raw = gyro.sample;
[gyro.q, gyro.cumQ] = func_quat_from_gyro(gyro.raw, params.data.rate);

% Preprocessing Mag
[calm, bias, ~] = magcal(mag.sample(1:500, :));
mag.calibrated = (mag.sample - bias) * calm;
[mag.diff, mag.inferred, mag.magnitude, mag.rmOri] = func_calc_diff(mag.calibrated, gyro.q, params);
[~, ~, ~, mag.rm] = func_calc_diff(mag.calibrated, gyro.q, params);
mag.mean = movmean(mag.diff, params.pre.movWinSize);
mag.originMean = mag.mean;

% Preprocessing acc
acc.magnitude = sqrt(sum(filtfilt(params.pre.fHBAcc, params.pre.fHAAcc, acc.sample).^2, 2));    

% Detect events
detect = func_detect_events(mag, acc, params);
idx = find(detect.all);
detected = [];

params.ref.path = 'templates2/reference.mat';

[mdls, ref] = func_make_model(params.ref.path, 30, {'knn'});
ref = func_reference_update(ref, params);
mdl = mdls('knn');

src = [];
dst = [];

isChargeable = func_isChargeable(ori(accId).name);

attached.id = "NIL";
attached.bias = [0, 0, 0];
attached.lst = [];
allAcc = [params.global.all, 'NIL'];


% Identify
while ~isempty(idx)
    pnt = idx(1);
    idx = idx(2:end);

    if pnt < 500
        continue;
    end

    [bias, s, d] = func_compute_bias_margin(mag, gyro, attached.bias, pnt, ...
               params, params.identify.prc, true, attached.id ~= "NIL");

    if attached.id ~= "NIL"
        bias = -bias;
    end

    [~, scores] = predict(mdl, bias);
    probs = exp(scores) ./ sum(exp(scores),2);
    [probsx, identified] = sort(probs, 'descend');
    identified = allAcc(identified);

    identified(xor(isChargeable, ismember(identified, params.global.chargable))) = [];
    
    identified = identified(1);
    
    % Magnitude thresholding
    if sqrt(sum(bias.^2)) < 20
        continue;
    end

    src(end + 1) = s.pts(11);
    dst(end + 1) = d.pts(11);
    detected(end + 1) = pnt;

    if attached.id ~= "NIL"
        attached.id = "NIL";
        attached.bias = [0, 0, 0];
        
        mag = func_update_diff(mag, gyro.q, params, attached.bias, pnt);
        mag.mean = movmean(mag.diff, params.pre.movWinSize);

        detect= func_detect_events(mag, acc, params);
        idx = find(detect.all);
        idx = idx(idx>pnt);
    else
        attached.id = identified;
        attached.bias = bias;
        attached.lst(end+1, :) = bias;
        
        mag = func_update_diff(mag, gyro.q, params, attached.bias, pnt);
        mag.mean = movmean(mag.diff, params.pre.movWinSize);

        detect = func_detect_events(mag, acc, params);
        idx = find(detect.all);
        idx = idx(idx>pnt);

    end

end

refDetect = 2415;

margin = 500 + refDetect - 300;
% margin = 500;
last = length(mag.sample);
last = margin + 1000;

% For clearly extract ranges
detected = detected(detected > margin & detected < last);
detected = detected - margin;

event = event(event > margin & event < last);
event = event - margin;

interval = [detected - 100, detected + 100];


src = src(src > margin & src < last);
src = src - margin;
dst = dst(dst > margin & dst < last);
dst = dst - margin;

start = detected(1);

diff = zeros(length(mag.calibrated), 3);
refMag = mag.calibrated(start - 1, :);

for cnt = start:length(mag.calibrated)
    euler = gyro.raw(cnt, :) * 0.01;
    rotm = eul2rotm(euler, 'XYZ');

    refMag = (rotm\(refMag)')';
    
    diff(cnt, :) = mag.calibrated(cnt, :) - refMag;
end

nRow = 3;
nCol = 1;
fig = figure(49);
% fig.Position(1:4) = [100, 200, 300, 300];
clf

% Plot calibrated magnetometer
subplot(nRow, nCol, 1)
plot(acc.sample(margin:last, :))
% plot(diff(margin:end, :)
hold on
detectLine = xline(detected, '-', 'Detected');
gtLine = xline(event, '-', 'groundtruth');
rangeLineStart = xline(src, '-', 'src');

xl = xline(interval, '-', 'interval');

rangeLineEnd = xline(dst, '-', 'dst');

% ylim([-50 200])

title('Calibrated mag')

subplot(nRow, nCol, 2)
plot(mag.diff(margin:last, :))
hold on
detectLine = xline(detected, '-', 'Detected');
gtLine = xline(event, '-', 'groundtruth');
xl = xline(interval, '-', 'interval');
% ylim([0 10])

title('Diff')

subplot(nRow, nCol, 3)
plot(mag.mean(margin:last, :))
hold on
detectLine = xline(detected, '-', 'Detected');
% gtLine = xline(event, '-', 'groundtruth');
rangeLineStart = xline(src, '-', 'src');

xl = xline(interval, '-', 'interval');

rangeLineEnd = xline(dst, '-', 'dst');
title('Mag moving average filter')


return;
%% Find charging timestamp compared to detected points
step0_parameter

info = struct();
info.attach = [];
info.detach = [];

for cnt = 1:length(ori)
    flag = sum(ismember(params.global.chargable, ori(cnt).name));

    if flag == 0
        continue;
    end
    
    charge = charging(ismember({charging.name}, ori(cnt).name));

    if length(ori(cnt).trial) ~= length(charge.trial)
        disp([ori(cnt).name, ' : not matched with charging length'])
        continue;
    end

    for cnt2 = 1:length(ori(cnt).trial)
        cur = ori(cnt).trial(cnt2);
        curCharging = charge.trial(cnt2).charging.sample;

        mag = cur.rmag;
        gyro = cur.gyro;
        acc = cur.acc;
        event = cur.detect.sample;
        
        % Preprocessing gyro
        gyro.raw = gyro.sample;
        [gyro.q, gyro.cumQ] = func_quat_from_gyro(gyro.raw, params.data.rate);
        
        % Preprocessing Mag
        [calm, bias, ~] = magcal(mag.sample(1:500, :));
        mag.calibrated = (mag.sample - bias) * calm;
        [mag.diff, mag.inferred] = func_calc_diff(mag.calibrated, gyro.q);
        mag.mean = movmean(mag.diff, params.pre.movWinSize);
        mag.originMean = mag.mean;
        % mag.magnitude = sqrt(sum(filtfilt(params.pre.fHB, params.pre.fHA, mag.calibrated).^2, 2));
        
        % Preprocessing acc
        acc.magnitude = sqrt(sum(filtfilt(params.pre.fHBAcc, params.pre.fHAAcc, acc.sample).^2, 2));    
        
        % Detect events
        detect = func_detect_events(mag, acc, params);
        idx = find(detect.all);
        detected = [];
        
        margin = 500;
        isChargeable = func_isChargeable(ori(cnt).name);

        attached.id = "NIL";
        attached.bias = [0, 0, 0];
        attached.lst = [];
        
        % Identify
        while ~isempty(idx)
            pnt = idx(1);
            idx = idx(2:end);
            
            if pnt < 500
                continue;
            end

            pRange = pnt:pnt + 300;
            chargingRange = pnt:pnt + 500;
            
            % Detected event
            if sum(ismember(event, pRange)) > 0 && sum(ismember(curCharging, chargingRange)) > 0
                x = find(ismember(event, pRange), 1);
                y = find(ismember(curCharging, chargingRange), 1);
                y = curCharging(y);

                if mod(x, 2) == 0
                    info.detach(end + 1) = y-pnt;
                else
                    info.attach(end + 1) = y-pnt;
                end
            end
            
        
            [bias, s, d] = func_compute_bias_margin(mag, gyro, attached.bias, pnt, ...
                       params, params.identify.prc, true, attached.id ~= "NIL");
        
            if attached.id ~= "NIL"
                bias = -bias;
            end
        
            [~, scores] = predict(mdl, bias);
            probs = exp(scores) ./ sum(exp(scores),2);
            [probsx, identified] = sort(probs, 'descend');
            identified = allAcc(identified);
        
            identified(xor(isChargeable, ismember(identified, params.global.chargable))) = [];
            
            identified = identified(1);
            
            % Magnitude thresholding
            if sqrt(sum(bias.^2)) < 20
                continue;
            end
        
            if attached.id ~= "NIL"
                attached.id = "NIL";
                attached.bias = [0, 0, 0];
                [mag.diff(pnt:end, :), mag.inferred(pnt:end, :)] = func_calc_diff(mag.calibrated(pnt:end, :) - attached.bias, gyro.q(pnt:end, :));
                mag.mean = movmean(mag.diff, params.pre.movWinSize);
        
                detect= func_detect_events(mag, acc, params);
                idx = find(detect.all);
                detected = idx;
                idx = idx(idx>pnt);
        
                continue;
            end
        
            if attached.id == "NIL"
                attached.id = identified;
                attached.bias = bias;
                attached.lst(end+1, :) = bias;
        
                [mag.diff(pnt:end, :), mag.inferred(pnt:end, :)] = func_calc_diff(mag.calibrated(pnt:end, :) - attached.bias, gyro.q(pnt:end, :));
                mag.mean = movmean(mag.diff, params.pre.movWinSize);
        
                detect = func_detect_events(mag, acc, params);
                idx = find(detect.all);
                detected = idx;
                idx = idx(idx>pnt);
            else
                if strcmp(identified, attached.id)
                    attached.id = "NIL";
                    attached.bias = [0, 0, 0];
                    [mag.diff(pnt:end, :), mag.inferred(pnt:end, :)] = func_calc_diff(mag.calibrated(pnt:end, :) - attached.bias, gyro.q(pnt:end, :));
                    mag.mean = movmean(mag.diff, params.pre.movWinSize);
        
                    detect = func_detect_events(mag, acc, params);
                    idx = find(detect.all);
                    detected = idx;
                    idx = idx(idx>pnt);
                end
            end
        end
    end
end

%% Figure confusion matrix 140x140

lResult = 10;
cm = zeros(params.global.nObjects * lResult, params.global.nObjects * lResult);

[mdls, ref] = func_make_model(params.ref.path, 10, types);
ref = func_reference_update(ref, params);
select = {'charger3', 'wallet5', 'holder2'};
ref(~ismember({ref.name}, select)) = [];

% total = zeros(params.global.nObjects, params.global.nObjects, 3);
total = [];
% for cnt = 1:params.global.nObjects
% for cnt = 1:length(ref)
% 
%     total = [total;ref(cnt).feature];
% end

for cnt = 1:length(select)
    accName = select(cnt)

    total = [total;ref(ismember({ref.name}, accName)).feature];
end

dist = pdist(total , 'euclidean');

distMat = squareform(dist);

% corrData = corr(total');


% disp(corrData)


%% Figure Magnitude of Reference
load('features/ref2+3.mat');
ref = feature;

magnitudes = [];

for cnt = 1:length(ref)
    magnitude = sqrt(sum(ref(cnt).feature.^2, 2));
    magnitudes(end + 1) = mean(magnitude);a
end


disp(array2table(magnitudes, "VariableNames", {ref.name}))

%% Figure 

acc = ori(1).trial(5).acc;

figure(12)
clf

plot(acc.sample)