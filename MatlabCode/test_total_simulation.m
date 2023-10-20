clear exp
accId = 10;
trialId = 1;
wSize = 100;
rate = 100;
order = 4;

[b.low, a.low] = butter(4, 5/rate * 2, 'low');
[b.high, a.high] = butter(4, 10/rate * 2, 'high');

distanceThreshold = 40;
tmp = data(accId).trial(trialId);
accName = data(accId).name;

mag = tmp.rmag;
gyro = tmp.gyro;
acc = tmp.acc;
click = tmp.detect.sample;

mdlPath = '../MatlabCode/models/';
mdl = load([mdlPath, 'rotMdl2.mat']);
mdl = mdl.mdl;

featureMatrix.data = mdl.X;
featureMatrix.label = mdl.Y;

% For charging status
totalAcc = mdl.ClassNames;
chargingStatus = zeros(1, length(mag.sample));
chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2',...
    'holder3', 'holder4'};

if exist('charging', 'var')% Not a charging status
    % chargingAcc = {charging.name};

    idx = find(ismember(chargingAcc, accName), 1);
    if ~isempty(idx)
        chargingTime = charging(idx).trial(trialId).charging.sample;
        
        chargingStatus(chargingTime) = 1;
    end
end

chargingLatency = 200;
accessoryStatus = false; % attached : true, detached : false
startPoint = -1; % start points where accessory was initially detected
refPoint = -1; % reference point : detection points that has maximum value of magnitude
curPoints = []; 
prevPoints = [];

% For plotting
refPoints = [];
fpPoints = [];
class = {};

tic
interval = 100;
start = 100;
extractInterval = (-wSize*2:wSize);
calbrationInterval = (-6*wSize:-wSize);

[b.mag, a.mag] = butter(order, 10/rate * 2, 'high');

for t = start + 1:5:length(mag.sample)
    range = t + (-interval:-1);
    
    [flag, points] = func_detection(mag, acc, range, accessoryStatus, t);
    
    % Detect accessory attach or detach
    if flag
        curPoints = setdiff(unique([curPoints, points]), prevPoints);
        
        if ~isempty(curPoints)
            startPoint = curPoints(1);
        end
    end

    % Find a reference point for feature extraction.
    if startPoint ~= -1 && startPoint + interval <= t && refPoint == -1
        % select maximum magntiude in points
        magnitude = sum(filtfilt(b.mag, a.mag, mag.sample(startPoint:startPoint+interval-1, :)).^2, 2);
        tarIdx = curPoints - startPoint + 1;
        
        if tarIdx(end) > 100
            tarIdx = tarIdx(1):100;
        end

        refPoint = startPoint + find(magnitude == max(magnitude(tarIdx))) - 1;

        startPoint = -1;
        prevPoints = curPoints;
        curPoints = [];
    end

    % Feature extraction using charging status
    if refPoint ~= -1 && (refPoint + chargingLatency <= t || t == length(mag.sample))
        extractRange = refPoint + extractInterval;
        % calibrationRange = refPoint + calbrationInterval;
        % 
        % if calibrationRange(1) < 1
        %     calibrationRange = 1:calibrationRange(end);
        % end
        % calibrationRange = calibrationRange(mag.diffSum(calibrationRange) < calibrationThreshold);

        % [calm, bias, ~] = magcal(rmag.rawSample(calibrationRange, :));
        % [featureValue, inferredMag] = func_extract_feature((rmag.rawSample-bias)*calm, gyro.sample, extractRange, 4, rate);
        extractedRange = func_extract_range(mag.sample, gyro, extractRange, refPoint);

        [featureValue, ~] = func_extract_feature(mag.sample, gyro.sample, extractedRange, accessoryStatus);
    
        [~, distance] = knnsearch(featureMatrix.data, featureValue, 'K', 7, 'Distance', 'euclidean');

        if accessoryStatus
            s = 'attached';
        else
            s = 'detached';
        end

        disp(['Check distance!  accessory is ', s])
        disp(['Mean distance : ', num2str(mean(distance))])
        disp(['feature : ' ...
            num2str(featureValue(1)), ', ', num2str(featureValue(2)), ', ', ...
            num2str(featureValue(3))])
        disp(['refPoint : ', num2str(refPoint)])
        disp(['extractedRange : ' num2str(extractedRange(1)), '-', num2str(extractedRange(end))])

        % if (accessoryStatus == false && mean(distance) < distanceThreshold) || (accessoryStatus == true)
        if mean(distance) < distanceThreshold
            [preds, scores] = predict(mdl, featureValue);
            probs = exp(scores) ./ sum(exp(scores),2);

            label = func_predict({accName}, preds, probs, totalAcc, chargingAcc);

            disp(['Prob ', cell2mat(preds), '  label : ', cell2mat(label)])
            
            indices = ismember(featureMatrix.label, label);

            [~, distance] = knnsearch(featureMatrix.data(indices, :), featureValue, 'K', 7, 'Distance', 'euclidean');

            if mean(distance) < distanceThreshold
                if accessoryStatus == false
                    disp(['attach : ', char(label)])
                else
                    disp(['detach : ', char(label)])
                end  
                
                class{end + 1} = [char(label), '-', num2str(mean(distance))];
    
                accessoryStatus = ~accessoryStatus;        
                refPoints(end + 1) = refPoint;
            else
                fpPoints(end + 1) = refPoint;
            end
        else
            fpPoints(end + 1) = refPoint;
        end
        disp('end!')
        
        refPoint = -1;
    end
end


toc

% Plot for results
fig = figure(1);

% fig.Position(1:2) = [0, 200];
clf

nRow = 2;
nCol = 1;

colors = rand(5, 3);

subplot(nRow, nCol, 1)
hold on
plot(mag.diff)
title(accName)
stem(click, mag.diff(click, 2), 'filled')

legends = {'x', 'y', 'z', 'ground-truth'};

if ~isempty(refPoints)
    yt = mag.diff(refPoints, 2);
    text(refPoints, yt, class)
    stem(refPoints, mag.diff(refPoints, 2), 'filled')
    legends{end + 1} = 'ref';
end

if ~isempty(fpPoints)
    stem(fpPoints, mag.diff(fpPoints, 2), 'filled')
    legends{end + 1} = 'fp';
end

legend(legends)

[b.high, a.high] = butter(4, 10/rate * 2, 'high');
fh = filtfilt(b.high, a.high, mag.diffSum);

subplot(nRow, nCol, 2)
hold on
plot(fh)

return;
%% Plot reference points
figure(4)
clf

nRow = 1;
nCol = length(refPoints);

for cnt = 1:length(refPoints)
    ref = refPoints(cnt);
    extractRange = ref + extractInterval;

    calRange = ref + calbrationInterval;
    [calm, bias, expmfs] = magcal(rmag.rawSample(calRange, :));
    

    sample = (rmag.rawSample(extractRange, :)-bias)*calm;
    diff = zeros(length(extractRange), 3);
    refMag = sample(1, :);

    diff(1, :) = sample(1, :) - refMag; 

    for cnt2 = 2:length(extractRange)
        euler = gyro.sample(extractRange(cnt2), :) * 1/100;
        rotm = eul2rotm(euler, 'XYZ');

        refMag = (rotm\(refMag)')';

        diff(cnt2, :) = sample(cnt2, :) - refMag; 
    end
    
    subplot(nRow, nCol, cnt)
    plot(diff)
    
    if mod(cnt, 2) == 1
        title(['attach', num2str(ref)])
    else
        title(['detach', num2str(ref)])
    end
end


clearvars chargingTime
% plot(mag.diffSum)
% stem(totalRefPoints, mag.diffSum(totalRefPoints), 'filled')
% stem(totalStartPoints, mag.diffSum(totalStartPoints), 'filled')
% stem(totalEndPoints, mag.diffSum(totalEndPoints), 'filled')
% legend({'diffSum', 'ref', 'start', 'end'})

return;
%%

nRow = 5;
nCol = 1;

t = 2852;
range = t + (-100*2:100);
fig = figure(5);
clf


% Extract range for calibration
% calRange = t + calibrationInterval;

% Calibration magnetometer
% [calm, bias, ~] = magcal(rawSample(calRange, :));

[~, diff1s]= func_get_diff(mag.sample, gyro, calRange);

diffSum = sqrt(sum(diff1s.^2, 2));

% Magnetometer Calibration filtering
calRange = calRange(diffSum < calibrationThreshold);
% [calm, bias, ~] = magcal(rawSample(calRange, :));

[diffOriginal, diff1s]= func_get_diff((rawSample-bias)*calm, gyro, range);

diffSum = sqrt(sum(diff1s.^2, 2));

% LPF, HPF
fh = filtfilt(b.high, a.high, diffSum);
fl = filtfilt(b.low, a.low, diffSum);

% LPF derivative
hpfMaxIdx = find(max(fh) == fh);
tmp = fl((hpfMaxIdx-20):(hpfMaxIdx+20));
lpfMaxIdx = hpfMaxIdx - 20 -1 + find((max(tmp) == tmp));

% Detect로 간주
hpfMaxIdxGlobal = range(1) + hpfMaxIdx -1;

% Calculated diff filtered by hpf, lpf
hpfMaxIdxLocal = hpfMaxIdxGlobal - range(1)+ 1;

[diff, diff1s] = func_get_diff((rawSample-bias)*calm, gyro, range);

extractedRange = func_extract_range((rawSample-bias)*calm, gyro, range, hpfMaxIdxGlobal);
range = extractedRange - range(1) + 1;

lst = [range(1), hpfMaxIdxLocal, range(end)];
% Plotting
subplot(nRow, nCol, 1)
hold on
plot(diffOriginal)
stem(lst, diffOriginal(lst), 'filled')
title([num2str(t), '-', num2str(length(calRange))])

subplot(nRow, nCol, nCol + 1)
hold on
plot(diffSum)
title('diff sum')

subplot(nRow, nCol, nCol*2 + 1)
hold on
plot(fh)
stem(lst, fh(lst), 'filled')
title(['HPF ', num2str(highCutoff), 'Hz'])

subplot(nRow, nCol, nCol*3 + 1)
hold on
plot(fl)
stem(lst, fl(lst), 'filled')
title(['LPF ', num2str(lowCutoff), 'Hz'])

[featureValue, ~] = func_get_diff((rawSample    -bias)*calm, gyro, extractedRange);
    
if mod(cnt2, 2) == 1
    f = featureValue(end, :);
else
    f = -featureValue(end, :);
end

[preds, scores] = predict(mdl, f);
probs = exp(scores) ./ sum(exp(scores),2);

pLabel = func_predict({accName}, preds, probs, mdl.ClassNames, chargingAcc);

[midx, distance] = knnsearch(featureMatrix.data, f, 'K', 11, 'Distance', 'euclidean');

subplot(nRow, nCol, nCol*4 + 1)
hold on
plot(featureValue)
title([preds{1}, '-->', char(pLabel), ', ',num2str(mean(distance))])

f

% disp([accName, num2str(cnt2), '->', num2str(f(1)), ',',  num2str(f(2)), ',',  num2str(f(3))])

%%
function [diff, diff1s] = func_get_diff(mag, gyro, range)

diff = zeros(length(range), 3);
diff1s = zeros(length(range), 3);

refMag = mag(range(1), :);

for cnt = 2:length(range)
    t = range(cnt);

    euler = gyro.sample(t, :) * 1/100;
    rotm = eul2rotm(euler, 'XYZ');

    refMag = (rotm\(refMag)')';
    diff(cnt, :) = mag(t, :) - refMag;
    diff1s(cnt, :) = mag(t, :) - (rotm\(mag(t-1, :))')';
end

end

