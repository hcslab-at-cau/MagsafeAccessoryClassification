%% Identify MagSafe accessories
params.identify.nTotal = length(data(1).trial);
params.identify.nTrain = params.identify.nTotal * 0.2;
params.identify.nTest = params.identify.nTotal - params.identify.nTrain;


% mdl = load(['mdl/ref2/portable/rbfSVM','.mat']);
% mdl = mdl.m;

means = [];
vars = [];

for cnt = 1:length(ref)
    means(end + 1, :) = mean(ref(cnt).feature);
    vars(end + 1, :) = var(ref(cnt).feature);
end

result = struct();
tIdx = 1;
tic
for cnt = 1:params.identify.nRepeat    
    if rem(cnt, 10) == 0
        disp(cnt)
        toc
    end

    label = struct();
    labels = {data.name};
    % mdlClass = mdl.ClassNames;
    % curIdx = ismember(mdlClass, labels);

    for cnt2 = 1:length(labels)
        name = cell2mat(labels(cnt2));
        label(cnt2).name = name;
        label(cnt2).isChargeable = func_isChargeable(name);
    end
    

    if params.ref.self
        trainIdx = false(1, params.identify.nTotal);
        trainIdx(randperm(params.identify.nTotal, params.identify.nTrain)) = true;
    
        for cnt2 = 1:length(label)
            label(cnt2).feature(~trainIdx, :) = [];
            feature(cnt2).trial(trainIdx) = [];
        end
    end

    for cnt2 = 1:params.data.nObjects
        disp(cnt2)
        for cnt3 = 1:length(feature(cnt2).trial)
            cur = struct();
            cur.name = data(cnt2).name;
            cur.class = cnt2;
            cur.isChargeable = func_isChargeable(cur.name);

            if params.data.raw
                mag = feature(cnt2).trial(cnt3).rmag;
            else
                mag = feature(cnt2).trial(cnt3).mag;
            end

            gyro = feature(cnt2).trial(cnt3).gyro;
            acc = feature(cnt2).trial(cnt3).acc;

            cur.event = feature(cnt2).trial(cnt3).event.sample;
            cur.event = reshape(cur.event, 2, length(cur.event)/2)';
            
            cur.detect = func_detect_events(mag, acc, params);

            cur.identify.id = zeros(1, length(cur.detect.all));
            cur.identify.bias = zeros(length(cur.detect.all), 3);
            cur.identify.fBias = zeros(length(cur.detect.all), 3);

            for cnt4 = 1:size(cur.event, 1)
                range = max(1, cur.event(cnt4, 1) - params.identify.testMargin): ...
                    min(length(cur.detect.all), cur.event(cnt4, 2) + params.identify.testMargin);
                idx = find(cur.detect.all(range)) + range(1) - 1;

                attached.id = params.data.nObjects + 1;
                attached.bias = [0, 0, 0];

                pnt = 1;

                while ~isempty(idx)
                    pnt = idx(1);
                    idx = idx(2:end);
                    % 
                    % diff = func_compute_bias(mag, gyro, attached.bias, pnt, ...
                    %    params.identify.searchRange, params.identify.featureRange, params.identify.prc, true);           

                    diff = func_compute_bias_margin(mag, gyro, attached.bias, pnt, ...
                       params, params.identify.prc, true, attached.id ~= params.data.nObjects + 1);    

                    if attached.id ~= params.data.nObjects + 1
                        diff = -diff;
                    end

                    [~, scores] = predict(mdl, diff);
                    probs= exp(scores) ./ sum(exp(scores),2);
                    [~, identified] = sort(probs, 'descend');
                    identified([label(identified).isChargeable] ~= cur.isChargeable) = [];
                    
                    identified = identified(1);
                    % disp(identified)

                    % Magnitude thresholding
                    if sqrt(sum(diff.^2)) < 20
                        cur.identify.id(pnt) = -identified;
                        cur.identify.fBias(pnt, :) = diff;

                        continue;
                    end

                    % diff = means(identified, :);


                    if attached.id == params.data.nObjects + 1
                        % Attach
                        cur.identify.id(pnt) =  identified;
                        cur.identify.bias(pnt, :) = means(identified, :);

                        attached.id = identified;
                        attached.bias = diff;

                        [mag.diff(pnt:end, :), mag.inferred(pnt:end, :)] = func_calc_diff(mag.calibrated(pnt:end, :) - attached.bias, gyro.q(pnt:end, :));
                        mag.mean = movmean(mag.diff, params.pre.movWinSize);

                        cur.detect = func_detect_events(mag, acc, params);
                        idx = find(cur.detect.all(range)) + range(1) - 1;
                        idx = idx(idx > pnt + 100);
                    else
                        if identified == attached.id 
                            % Detach
                            cur.identify.id(pnt) = params.data.nObjects + 1;
                            cur.identify.bias(pnt, :) = [0, 0, 0];

                            attached.id = params.data.nObjects + 1;
                            attached.bias = [0, 0, 0];
                            [mag.diff(pnt:end, :), mag.inferred(pnt:end, :)] = func_calc_diff(mag.calibrated(pnt:end, :) - attached.bias, gyro.q(pnt:end, :));
                            mag.mean = movmean(mag.diff, params.pre.movWinSize);

                            cur.detect = func_detect_events(mag, acc, params);
                            idx = find(cur.detect.all(range)) + range(1) - 1;
                            idx = idx(idx > pnt + 100);
                        else
                            % False-positive
                            cur.identify.id(pnt) = -identified;
                            cur.identify.fBias(pnt, :) = diff;
                        end
                    end
                end

            end

            result.trial(tIdx) = cur;
            tIdx = tIdx + 1;
            
            % if params.data.raw
            %     feature(cnt2).trial(cnt3).rmag = mag;
            % else
            %     feature(cnt2).trial(cnt3).mag = mag;
            % end

        end
    end
end