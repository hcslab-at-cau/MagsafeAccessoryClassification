wSize= 100;
extractInterval = (wSize*1:wSize*5);
varTable = struct();


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
        samples = mag.sample;

        tmp = struct();

        for cnt3 = iter
            clickTime = click(cnt3);
            range = clickTime + extractInterval;
            idx = find(iter == cnt3);

            if range(end) > length(mag.sample)
                range = range(1):length(mag.sample);
            end


            for cnt4 = 1:length(objectFeature)
                obj = objectFeature(cnt4);
                
                sample = samples(range, :)-obj.feature;
                diff = zeros(length(range), 3);
    
                for t = 2:length(range)
                    euler = gyro.sample(range(t), :) * 1/rate;
                    rotm = eul2rotm(euler, 'XYZ');

                    diff(t, :) = sample(t, :) - (rotm\(sample(t-1, :))')';
                end

                tmp(idx).trial(cnt4).var = sum(var(diff.'));
            end
            
            values = cell2mat({tmp(idx).trial.var});
            minIdx = find(values == min(values));

            tmp(idx).predicted = objectFeature(minIdx).name;
            
            Y = [Y, {accName}];
            predictedY = [predictedY, {objectFeature(minIdx).name}];
        end


        varTable(cnt).trial(cnt2).result = tmp;
    end

end


fig = figure('Name', 'confusion matrix');
% fig.Position(1:4) = [200, 0, 800, 800]; 

totalAcc = {objectFeature.name};

c = confusionmat(Y, predictedY, "Order", totalAcc);
cm = confusionchart(c, totalAcc);
sortClasses(cm, totalAcc)
cm.RowSummary = 'row-normalized';
title('confusion matrix');


return;
%% Test diff 1s affects
accId = 2;
trialId = 2;

wSize= 100;
[b.high, a.high] = butter(4, 10/rate * 2, 'high');


attachInterval = (-2*wSize:wSize);
extractInterval = (wSize*1:wSize*5);

cur = data(accId).trial(trialId);
mag = cur.mag;
rmag = cur.rmag;
gyro = cur.gyro;
click = cur.detect.sample;


[calm, bias, ~] = magcal(rmag.rawSample(1:500, :));

magSample = mag.sample;
% magSample = (rmag.rawSample-bias)*calm;
diff = zeros(length(magSample), 3);

for cnt = 2:length(magSample)
    euler = gyro.sample(cnt, :) *1/100;
    rotm = eul2rotm(euler, 'XYZ');

    diff(cnt, :) = magSample(cnt, :) - (rotm\(magSample(cnt-1 ,:))')';
end

diffSum = sum(diff.^2, 2);

figure(1)
clf

hold on
plot(diff)
stem(click, diff(click), "filled")


figure(2)
clf

iter = 1:2:length(click);

nRow = length(data) + 1;
nCol = length(iter);

varTable = struct();


for cnt = iter
    t = click(cnt);

    idx = find(iter == cnt);

    attachRange = t + attachInterval;

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

    varTable(idx).('original') = sum(var(diff.'));

    subplot(nRow, nCol, idx)
    plot(diff)
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
        
        varTable(idx).trial(cnt2).feature = sum(var(diff.'));

        subplot(nRow, nCol, nCol*(cnt2)+idx)
        plot(diff)
        title([data(accId).name, '-', obj.name])
    end

    values = cell2mat({varTable(idx).trial.feature});

    minIdx = find(min(values) == values);
    varTable(idx).predicted = objectFeature(minIdx).name; 

    disp(['Original : ', data(accId).name, ' selected : ', objectFeature(minIdx).name])
end