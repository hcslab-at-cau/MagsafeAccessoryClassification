wSize= 100;
extractInterval = (wSize*1:wSize*4);
varTable = struct();
chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};
totalAcc = {objectFeature.name};
totalAcc{end + 1} = 'undefined';

idx = ismember({data.name}, {'None'});
if ~isempty(find(idx, 1))
    data = data(~idx);
end

% idx = find(ismember(totalAcc, 'wallet2'));
% objectFeature(idx).feature = [-40, 70, 30];

Y = [];
predictedY = [];

parfor cnt = 1:length(data)
    accName = data(cnt).name;
    nTrials = length(data(cnt).trial);
    varTable(cnt).name = accName;

    for cnt2 = 1:nTrials
        cur = data(cnt).trial(cnt2);
        mag = cur.mag;
        rmag = cur.rmag;
        gyro = cur.gyro;
        click = cur.detect.sample;
        iter = 1:2:length(click);

        [calm, bias, ~] = magcal(rmag.rawSample(1:500, :));
        samples = (rmag.rawSample-bias)*calm;
        % samples = mag.sample;

        tmp = struct();

        for cnt3 = iter
            clickTime = click(cnt3);
            range = clickTime + extractInterval;
            idx = find(iter == cnt3);

            if range(end) > length(mag.sample)
                range = range(1):length(mag.sample);
            end

            sample = samples(range, :);

            diff = zeros(length(range), 3);
    
            for t = 2:length(range)
                euler = gyro.sample(range(t), :) * 1/rate;
                rotm = eul2rotm(euler, 'XYZ');

                diff(t, :) = sample(t, :) - (rotm\(sample(t-1, :))')';
            end

            noObjDiff =sum(var(diff));

            for cnt4 = 1:length(objectFeature)
                obj = objectFeature(cnt4);
                
                sample = samples(range, :)-obj.feature;
                diff = zeros(length(range), 3);
    
                for t = 2:length(range)
                    euler = gyro.sample(range(t), :) * 1/rate;
                    rotm = eul2rotm(euler, 'XYZ');

                    diff(t, :) = sample(t, :) - (rotm\(sample(t-1, :))')';
                end

                tmp(idx).trial(cnt4).var = sum(var(diff));
            end
            
            
            values = cell2mat({tmp(idx).trial.var});
            minIdx = find(values == min(values));
            
            if min(values) > noObjDiff
                Y = [Y, {accName}];
                predictedY = [predictedY, {'undefined'}];
                % disp('undefined')
                continue;
            end

            probs = func_make_prob(values);

            label = func_predict({accName}, {objectFeature(minIdx).name}, probs, totalAcc, chargingAcc);
            % label = {objectFeature(minIdx).name};
            tmp(idx).predicted = label;
            
            Y = [Y, {accName}];
            predictedY = [predictedY, label];
        end

        varTable(cnt).trial(cnt2).result = tmp;
    end

end


fig = figure('Name', 'confusion matrix');
% fig.Position(1:4) = [200, 0, 800, 800]; 

c = confusionmat(Y, predictedY, "Order", totalAcc);
cm = confusionchart(c, totalAcc);
sortClasses(cm, totalAcc)
cm.RowSummary = 'row-normalized';
title('confusion matrix');

return;
%% Test diff 1s affects
accId = 2;
trialId = 1;

chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};
accName = data(accId).name;
totalAcc = {objectFeature.name};

wSize= 100;
[b.high, a.high] = butter(4, 10/rate * 2, 'high');

attachInterval = (-2*wSize:wSize);
extractInterval = (1*wSize:wSize*4);

cur = data(accId).trial(trialId);
start = results(accId).trial(trialId).start

mag = cur.mag;
rmag = cur.rmag;
gyro = cur.gyro;
click = cur.detect.sample;

[calm, bias, ~] = magcal(rmag.rawSample(1:start, :));

% magSample = mag.sample;
magSample = (rmag.rawSample-bias)*calm;
diff = zeros(length(magSample), 3);


for cnt = 2:length(magSample)
    euler = gyro.sample(cnt, :) *1/100;
    rotm = eul2rotm(euler, 'XYZ');

    diff(cnt, :) = magSample(cnt, :) - (rotm\(magSample(cnt-1 ,:))')';
end

diffSum = sum(diff.^2, 2);

figure(1)
clf

subplot(2, 1, 1)
hold on
plot(diff)
stem(click, diff(click), "filled")

varDiff = zeros(length(diff), 1);

for cnt = 101:length(diff)
    range = cnt + (-100:-1);

    varDiff(cnt) = sum(sqrt(mean(diff(range, :)).^2));
end


subplot(2, 1, 2)
hold on
plot(varDiff)
stem(click, varDiff(click), "filled")


figure(2)
clf

iter = 1:2:length(click);

nRow = length(objectFeature) + 1;
nCol = length(iter);

varTable = struct();


for cnt = iter
    t = click(cnt);

    idx = find(iter == cnt);

    % magnitude = sum(filtfilt(b.high, a.high, mag.sample(attachRange, :)).^2, 2);
    % detect = find(max(magnitude) == magnitude) + attachRange(1) - 1;
    
    range = t + extractInterval;
    
    if range(end) > length(mag.sample)
        range = range(1):length(mag.sample);
    end

    diff = zeros(length(range), 3);

    sample = magSample(range, :);

    for cnt3 = 2:length(range)
        euler = gyro.sample(range(cnt3), :) * 1/100;
        rotm = eul2rotm(euler, 'XYZ');
        
        diff(cnt3, :) = sample(cnt3, :) - (rotm\(sample(cnt3-1, :))')';
    end

    diffSum = sum(diff.^2, 2);

    varTable(idx).('original') = sum(var(diff));

    % t = t - range(1) + 1;
    subplot(nRow, nCol, idx)
    hold on
    plot(diff)
    % ylim([-5 5])
    % stem(t, diff(t), 'filled')
    title('Original')
    
    for cnt2 = 1:length(objectFeature)
        obj = objectFeature(cnt2);
        sample = magSample(range, :)-obj.feature;

        diff = zeros(length(range), 3);

        for cnt3 = 2:length(range)
            euler = gyro.sample(range(cnt3), :) * 1/100;
            rotm = eul2rotm(euler, 'XYZ');
            
            diff(cnt3, :) = sample(cnt3, :) - (rotm\(sample(cnt3-1, :))')';
        end

        diffSum = sum(diff.^2, 2);
        
        varTable(idx).trial(cnt2).feature = sum(var(diff));

        subplot(nRow, nCol, nCol*(cnt2)+idx)
        hold on
        plot(diff)
        % ylim([-5 5])
        % stem(t, diff(t), 'filled')
        title([data(accId).name, '-', obj.name])
    end

    values = cell2mat({varTable(idx).trial.feature});
    
    minIdx = find(min(values) == values);

    probs = func_make_prob(values);
    label = func_predict({accName}, {objectFeature(minIdx).name}, probs, totalAcc, chargingAcc);
    

    varTable(idx).predicted = label;
    
    disp(['Original : ', data(accId).name, ' selected : ', char(label)])
end

return;
%%
accId = 1;
trialId = 1;

cur = data(accId).trial(trialId);
mag = cur.mag;
rmag = cur.rmag;
gyro = cur.gyro;
click = cur.detect.sample;

nRow = 1 + length(objectFeature);
nRow = 1;
nCol = 1;

[calm, bias, ~] = magcal(rmag.rawSample(1:500, :));
mag.sample= (rmag.rawSample-bias)*calm;

diff1s = zeros(length(mag.sample), 3);

for cnt = 2:length(mag.sample)
    euler = gyro.sample(cnt, :) * 1/100;
    rotm = eul2rotm(euler, 'XYZ');

    diff1s(cnt, :) = mag.sample(cnt, :) - (rotm\(mag.sample(cnt-1, :))')';
end

figure(5)
clf

subplot(nRow, nCol, 1)
hold on
plot(diff1s)
stem(click, diff1s(click), 'filled')
title('diff1s ')


% for cnt = 1:length(objectFeature)
%     obj = objectFeature(cnt);
%     samples = mag.sample - obj.feature;
% 
%     diff1s = zeros(length(samples), 3);
% 
%     for cnt2 = 2:length(samples)
%         euler = gyro.sample(cnt2, :) * 1/100;
%         rotm = eul2rotm(euler, 'XYZ');
% 
%         diff1s(cnt2, :) = samples(cnt2, :) - (rotm\(samples(cnt2-1, :))')';
%     end
% 
%     subplot(nRow, nCol, cnt + 1)
%     plot(diff1s)
%     title([data(accId).name '-' obj.name])
% end


%% function for make scores

function result = func_make_prob(varValue)

varArray = 1 ./ varValue;
result = varArray / sum(varArray);

end