accName = 'wallet2';
accId = ismember({feature.name}, accName);
accIdx = ismember({result.trial.name}, accName);
cur = result.trial(accIdx);

fig = figure(41);
% fig.Position(1:2) = [100, 200];
clf 

nCol = 5;
nRow = length(cur)/nCol;
% nRow = 4;

b = [];
r = ref(ismember({ref.name}, accName));
f = cell2mat({r.feature});
means = mean(f);
    
refMean = [num2str(means(1)), ', ', num2str(means(2)), ', ', num2str(means(3))];

[bh, ah] = butter(4, 40/100 * 2, 'high');

for cnt = 1:nRow*nCol
    res = cur(cnt).identify;
    % detected = find(res.id(res.id > 0));
    % detected = find(res.id > 0);
    detected = find(~strcmp(res.id, "") & ~strcmp(res.id, "WR"))';
    % fp = find(res.id < 0);
    fp = find(strcmp(res.id, "WR"));
    value = feature(accId).trial(cnt);
    rmag = feature(accId).trial(cnt).rmag;
    gyro = feature(accId).trial(cnt).gyro;
    acc = feature(accId).trial(cnt).acc;
    event = cur(cnt).event;
    
    sample = rmag.calibrated;

    refMag = sample(1, :);
    diff = [];

    for cnt2 = 2:length(gyro.raw)
        euler = gyro.raw(cnt2, :) * 0.01;
        rotm = eul2rotm(euler, 'XYZ');

        refMag = (rotm\(refMag)')';
        diff(end + 1, :) = sample(cnt2, :) - refMag;
    end
    
    % plotData = rmag.rmOri;
    % plotData = diff;
    plotData = gyro.raw;

    if cnt == 2
       tmpk = diff;
   end

    n = fix((cnt-1)/nCol)*nCol + mod(cnt-1, nCol) + 1;
    subplot(nRow, nCol, n)
    plot(plotData)
    % ylim([0 0.1])
    gtLine = xline(event, '-', 'gt');

    hold on
    yl =  ylim;

    attached.bias = zeros(1, 3);
    for k = 1:length(detected)
        idx = detected(k);

        if res.id(idx) ~= ""
            [diff, src, dst, flag] = func_compute_bias_margin(rmag, gyro, attached.bias, idx, params, params.identify.prc, true, res.id(idx) == "NIL");     
            stem(src.pts(11), plotData(src.pts(11), 1), 'filled')
            stem(dst.pts(11), plotData(dst.pts(11), 1), 'filled')
        
            txt = [num2str(idx), ' , ', num2str(diff(1)), ' , ', num2str(diff(2)), ' , ', num2str(diff(3)), ':', num2str(res.id(idx))];
            % text(cnt2, yl(2)-10, txt, 'HorizontalAlignment','right', 'FontSize', 5)

            hx = xline(idx, '-', {txt});
            hx.FontSize = 7;
            hx.LineWidth = 0.2;


            if res.id(idx) == accName || res.id(idx) == "NIL"

            else
                hx.Color = [1.0 0, 0];
            end
            
            if attached.bias(1) == 0
                attached.bias = diff;
            else
                attached.bias = zeros(1, 3);
            end
            
           
        end
    end


    if ~isempty(fp)
        for idx = fp'
            [diff, src, dst] = func_compute_bias(rmag, gyro, attached.bias, idx, ...
                           params.identify.searchRange, params.identify.featureRange, params.identify.prc, true);

            stem(src.pts(11), plotData(src.pts(11), 1), 'filled')
            stem(dst.pts(11), plotData(dst.pts(11), 1), 'filled')

            hx = xline(idx);
            hx.FontSize = 5;
            hx.LineWidth = 0.1;
            hx.Color = [0 0 1];
        end
    end
end


% disp(['Mean : ', num2str(mean(b)), ', Var : ', num2str(var(b))])
% disp(['Ref Mean : ', num2str(mean(f)), ', Var : ', num2str(var(f))])

return;
%% Plotting moving average

figure(24)
clf

for cnt = 1:length(cur)
    res = cur(cnt).identify;
    detected = find(res.id);
    rmag = feature(accId).trial(cnt).rmag;

    n = fix((cnt-1)/nCol)*nCol + mod(cnt-1, nCol) + 1;
    subplot(nRow, nCol, n)
    plot(rmag.mean)
    

    if cnt == 1
        title(cur(1).class)
    end

    yl =  ylim;

    hold on
    for cnt2 = 1:length(detected)
        idx = detected(cnt2);

        if res.id(idx) == -1
            tmp = res.fBias(idx, :);
            
        else
            tmp = res.bias(idx, :);
        end
        [diff, src, dst] = func_compute_bias(mag, gyro, attached.bias, idx, ...
                   params.identify.searchRange, params.identify.featureRange, params.identify.prc);
            
        stem(src.pts, rmag.mean(src.pts), 'filled')
        stem(dst.pts, rmag.mean(dst.pts), 'filled')

        txt = [num2str(tmp(1)), ' , ', num2str(tmp(2)), ' , ', num2str(tmp(3))];
        % text(cnt2, yl(2)-10, txt, 'HorizontalAlignment','right', 'FontSize', 5)
        hx = xline(idx);
        % hx.FontSize = 7;
    end
end

%% Plotting Diff

acc = 'batterypack1';
nOri = ori;

cur = nOri(ismember({nOri.name}, acc));

if params.data.pre
    pre = func_load_new_data('../Data/User/pre', char({'524'}));
    
    [calm, bias, ~] = magcal(pre(1).trial(1).rmag.sample(600:1000, :));
end

figure(5)
clf

nRow = 6;
nCol = 5;

for cnt = 1:nRow
    rmag = cur.trial(cnt).rmag;
    gyro = cur.trial(cnt).gyro;
    detect = cur.trial(cnt).detect.sample;
    
    [calm, bias, ~] = magcal(rmag.sample(1:500, :));
    rmag.sample = (rmag.sample-bias)*calm;

    iter = 1:2:length(detect);

    for cnt2 = 1:length(iter)
        p = detect(iter(cnt2));
        
        refP = p - 400;
        endP = p + 100;

        refMag = rmag.sample(refP-1, :);
        diff = [];

        for cnt3 = refP:endP-1
            euler = gyro.sample(cnt3, :) * 0.01;
            rotm = eul2rotm(euler, 'XYZ');
            refMag = (rotm\(refMag)')';
        
            diff(end + 1, :) = rmag.sample(cnt3, :) - (rotm\(refMag)')';
        end
            
        subplot(nRow, nCol, (cnt-1)*nCol + cnt2)
        plot(diff)
        % hold on
        % legend({'x', 'y', 'z'})
    end
end

%%
params.detect.magTh = .5;
params.detect.diffTh = 2;

params.detect.margin = params.data.rate * 0.1 * 2 + 1;
params.detect.minDist = params.data.rate * 1;

params.identify.testMargin = params.data.rate * 3;

params.identify.searchRange = params.data.rate * .75;
params.identify.featureRange = params.data.rate * .05;
params.identify.prc = [10, 90];


acc = 'wallet1';
nOri = ori;

cur = nOri(ismember({nOri.name}, acc));

r = ref(ismember({ref.name}, acc));
f = cell2mat({r.feature});
means = mean(f);

refMean = [num2str(means(1)), ', ', num2str(means(2)), ', ', num2str(means(3))];

figure(6)
clf

nRow = 6;
nCol = 1;

[b, a] = butter(4, 40/100 * 2, 'high');

for cnt = 1:nRow
    rmag = cur.trial(cnt).mag;
    gyro = cur.trial(cnt).gyro;
    acc = cur.trial(cnt).acc;
    detect = cur.trial(cnt).detect.sample;
    
    % [calm, bias, ~] = magcal(rmag.sample(1:500, :));
    [gyro.q, gyro.cumQ] = func_quat_from_gyro(gyro.sample, params.data.rate);

    rmag.calibrated = (rmag.sample-bias)*calm;

    [rmag.diff, rmag.inferred] = func_calc_diff(rmag.calibrated, gyro.q);
    rmag.mean = movmean(rmag.diff, params.pre.movWinSize);

    % Extract the magnitude of high-pass filtered samples  
    rmag.magnitude = sqrt(sum(filtfilt(params.pre.fHB, params.pre.fHA, rmag.calibrated).^2, 2));  
    detected = func_detect_events(rmag, acc, params);
    detected = find(detected.all);

    refMag = rmag.calibrated(1, :);
    % diff = [];
    % 
    % for cnt3 = 2:length(rmag.calibrated)
    %     euler = gyro.sample(cnt3, :) * 0.01;
    %     rotm = eul2rotm(euler, 'XYZ');
    % 
    %     refMag = (rotm\(refMag)')';
    % 
    %     diff(end + 1, :) = rmag.calibrated(cnt3, :) - (rotm\(refMag)')';
    % end

    % sample = sqrt(sum(filtfilt(b, a, acc.sample).^2, 2)); 
    % acc.sample(:, 3) = acc.sample(:, 3) * 10;
    % acc.sample(:, 2) = acc.sample(:, 3) * 10;

    sample = sum(filtfilt(b, a, acc.sample(:, 1:3)).^2, 2);
    % sample = filtfilt(b, a, acc.sample(:, 1:3)).^2;
    % sample = acc.sample;
    subplot(nRow, nCol, cnt)
    plot(sample)
 
    hold on
    if cnt == 1
        title(refMean)
    end
    ylim([0, 0.01])
    % findpeaks(sample, 'MinPeakDistance', 50)
    % detected = detected(s == detected);

    % stem(detected, sample(detected), 'LineStyle', 'none', 'MarkerFaceColor','red',...
    %  'MarkerEdgeColor','green')

    stem(detected, sample(detected), 'LineStyle','none')
    hx = xline(detect);

    for cnt2 = 1:length(hx)
        hx(cnt2).Color = [1.0, 0, 0];
        hx(cnt2).LineWidth = 1.5;
    end

    % for cnt3 = 1:2:length(detect)
    %     pnt = detect(cnt3);
    %     s = pnt-200;
    %     e = pnt+100;
    % 
    %     idx = detected(detected > s & detected < e);
    % 
    %     if ~isempty(idx)
    %         if length(idx) ~= 1
    %             idx = idx(end);
    %         end
    % 
    %         [v, src, dst] = func_compute_bias(rmag, gyro, [0, 0, 0], idx, ...
    %                params.identify.searchRange, params.identify.featureRange, params.identify.prc, true);
    % 
    %         stem(src.pts(11), diff(src.pts(11), 2), 'filled')
    %         stem(dst.pts(11), diff(dst.pts(11), 2), 'filled')
    % 
    %         txt = [num2str(v(1)), ' , ', num2str(v(2)), ' , ', num2str(v(3))];
    %         % text(cnt2, yl(2)-10, txt, 'HorizontalAlignment','right', 'FontSize', 5)
    % 
    %         hx = xline(idx, '-', {txt});
    %         hx.FontSize = 7;
    % 
    %     end
    % end
end

%% 
accName = 'wallet5';
accId = ismember({feature.name}, accName);
accIdx = ismember({result.trial.name}, accName);
gResult = result.trial(accIdx);

gCur = feature(accId).trial;

[b.h, a.h] = butter(4, 1/100 * 2, "High");

mdl = load(['./mdl/ref/portable/', 'linearSVM', '.mat']);
mdl = mdl.m;

figNum = 100;
nRow = 2;
nCol = 5;

for cnt = 1:2
    cur = gCur(5*(cnt-1) + 1:5*(cnt));
    
    figure(figNum + 1)
    clf

    for cnt2 = 1:length(cur)
        res = gResult(cnt2 + 5*(cnt-1)).identify;
        detected = find(res.id > 0);
        fp = find(res.id < 0);

        detected = [detected, fp];

        mag = cur(cnt2).rmag;
        gyro = cur(cnt2).gyro;

        diff = zeros(length(mag.calibrated), 3);
        refMag = mag.calibrated(1, :);

        for cnt3 = 2:length(mag.calibrated)
            euler = gyro.raw(cnt3, :) * 0.01;
            rotm = eul2rotm(euler, 'XYZ');
            refMag = (rotm\(refMag)')';
            
            diff(cnt3, :) = mag.calibrated(cnt3, :) - refMag;
        end
        
       subplot(nRow, nCol, cnt2)
       plot(diff)
       hold on
       for pnt = detected
            attached.bias = res.bias(pnt-1, :);

            params.identify.searchRange = 75;
            [~, src, dst] = func_compute_bias_margin(mag, gyro, attached.bias, pnt, ...
                       params, params.identify.prc, true, res.id(pnt) == params.data.nObjects + 1);

            stem(src.pts(11), diff(src.pts(11), 1), 'filled', 'b')
            stem(dst.pts(11), diff(dst.pts(11), 1), 'filled', 'b')

            params.identify.searchRange = 100;
            
            [~, src, dst] = func_compute_bias_margin(mag, gyro, attached.bias, pnt, ...
                       params, params.identify.prc, true, res.id(pnt) == params.data.nObjects + 1);
            
            % stem(src.pts(11), diff(src.pts(11), 1), 'filled', 'g')
            % stem(dst.pts(11), diff(dst.pts(11), 1), 'filled', 'g')

            hx = xline(src.pts(11));
            hx.FontSize = 7;
            hx.LineWidth = 1;

            hx = xline(dst.pts(11));
            hx.FontSize = 7;
            hx.LineWidth = 1;

       end
       
       stem(fp, diff(fp), "filled", 'Color', 'r')
       
       plotData = filtfilt(b.h, a.h, mag.mean);

       subplot(nRow, nCol, nCol + cnt2)
       plot(mag.mean)
       hold on 

       for pnt = detected
            attached.bias = res.bias(pnt-1, :);

            params.identify.searchRange = 75;
            [~, src, dst] = func_compute_bias_margin(mag, gyro, attached.bias, pnt, ...
                       params, params.identify.prc, true, res.id(pnt) == params.data.nObjects + 1);

            stem(src.pts(11), mag.mean(src.pts(11), 1), 'filled', 'b')
            stem(dst.pts(11), mag.mean(dst.pts(11), 1), 'filled', 'b')

            params.identify.searchRange = 100;
            
            [~, src, dst] = func_compute_bias_margin(mag, gyro, attached.bias, pnt, ...
                       params, params.identify.prc, true, res.id(pnt) == params.data.nObjects + 1);
            
            % stem(src.pts(11), diff(src.pts(11), 1), 'filled', 'g')
            % stem(dst.pts(11), diff(dst.pts(11), 1), 'filled', 'g')

            hx = xline(src.pts(11));
            hx.FontSize = 7;
            hx.LineWidth = 1;

            hx = xline(dst.pts(11));
            hx.FontSize = 7;
            hx.LineWidth = 1;

       end


    end

    figNum = figNum + 1;
end


%% 
figure(125)
clf

[b, a] = butter(4, 40/100 * 2, 'high');

accId = 7;

nRow = length(ori(accId).trial);
nCol = 1;

for cnt = 1:length(ori(accId).trial)
    cur = ori(accId).trial(cnt);
    detect = cur.detect.sample;
    mag = cur.rmag;
    
    acc = cur.acc;
    sample = acc.sample;
    sample = sqrt(sum(filtfilt(b, a, sample(:, 2:3) * 10).^2, 2)); 


    subplot(nRow, nCol, cnt)
    plot(mag.sample)
    title("Raw acc")
    hold on
    xline(detect)

end

%% 


%%
function res = getResult(data, accName, mdl, params)
res = struct();

mag = data.mag;
gyro = data.gyro;
acc = data.acc;

attached.id = params.data.nObjects + 1;
attached.bias = [0, 0, 0];
isChargeable = func_isChargeable(accName);

res.detect = func_detect_events(mag, acc, params);
res.id = zeros(1, length(detect.all));
res.bias = zeros(length(detect.all), 3);

res.event = data.event.sample;
res.event = reshape(res.event, 2, length(res.event/2))';

range = max(1, res.event(cnt4, 1) - params.identify.testMargin): ...
                    min(length(cur.detect.all), res.event(cnt4, 2) + params.identify.testMargin);

idx = find(detect.all);

while ~isempty(idx)
    pnt = idx(1);
    idx = idx(2:end);      

    diff = func_compute_bias_margin(mag, gyro, attached.bias, pnt, ...
       params, params.identify.prc, true, attached.id ~= params.data.nObjects + 1);    

    if attached.id ~= params.data.nObjects + 1
        diff = -diff;
    end

    [~, scores] = predict(mdl, diff);
    probs= exp(scores) ./ sum(exp(scores),2);
    [~, identified] = sort(probs, 'descend');
    identified([label(identified).isChargeable] ~= isChargeable) = [];
    
    identified = identified(1);

    % Magnitude thresholding
    if sqrt(sum(diff.^2)) < 20
        res.id(pnt) = -identified;
        % cur.identify.fBias(pnt, :) = diff;

        continue;
    end

    if attached.id == params.data.nObjects + 1
        % Attach
        res.id(pnt) =  identified;
        res.bias(pnt, :) = means(identified, :);

        attached.id = identified;
        attached.bias = diff;

        [mag.diff(pnt:end, :), mag.inferred(pnt:end, :)] = func_calc_diff(mag.calibrated(pnt:end, :) - attached.bias, gyro.q(pnt:end, :));
        mag.mean = movmean(mag.diff, params.pre.movWinSize);

        res.detect = func_detect_events(mag, acc, params);
        idx = find(detect.all(range)) + range(1) - 1;
        idx = idx(idx>pnt);
    else
        if identified == attached.id 
            % Detach
            res.id(pnt) = params.data.nObjects + 1;
            res.bias(pnt, :) = [0, 0, 0];

            attached.id = params.data.nObjects + 1;
            attached.bias = [0, 0, 0];
            [mag.diff(pnt:end, :), mag.inferred(pnt:end, :)] = func_calc_diff(mag.calibrated(pnt:end, :) - attached.bias, gyro.q(pnt:end, :));
            mag.mean = movmean(mag.diff, params.pre.movWinSize);

            res.detect = func_detect_events(mag, acc, params);
            idx = find(detect.all(range)) + range(1) - 1;
            idx = idx(idx>pnt);
        else
            % False-positive
            res.id(pnt) = -identified;
            % cur.identify.fBias(pnt, :) = diff;
        end
    end
end

end