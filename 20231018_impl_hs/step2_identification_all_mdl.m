%% Identify MagSafe accessories
params.identify.nTotal = length(data(1).trial);
params.identify.nTrain = params.identify.nTotal * 0.2;
params.identify.nTest = params.identify.nTotal - params.identify.nTrain;
% allAcc = [params.global.all, 'unknown'];
allAcc = params.global.all;

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
        fprintf("%d ", cnt2);
        for cnt3 = 1:length(feature(cnt2).trial)
            % if cnt3 > 6
            %     continue;
            % end

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

            cur.detected = zeros(length(cur.detect.all), 1);
            cur.identify.id = strings(length(cur.detect.all), 1);
            cur.identify.bias = zeros(length(cur.detect.all), 3);
            cur.identify.fBias = zeros(length(cur.detect.all), 3);
            

            for cnt4 = 1:size(cur.event, 1)
                range = max(1, cur.event(cnt4, 1) - params.identify.testMargin): ...
                    min(length(cur.detect.all), cur.event(cnt4, 2) + params.identify.testMargin);
                idx = find(cur.detect.all(range)) + range(1) - 1;

                attached.id = "NIL";
                attached.bias = [0, 0, 0];

                pnt = 1;

                while ~isempty(idx)
                    pnt = idx(1);
                    idx = idx(2:end);     

                    diff = func_compute_bias_margin(mag, gyro, attached.bias, pnt, ...
                       params, params.identify.prc, true, attached.id ~= "NIL");    
                    
                    if attached.id ~= "NIL"
                        diff = -diff;
                    end

                    [~, scores] = predict(mdl, diff);
                    probs= exp(scores) ./ sum(exp(scores),2);
                    [probsx, identified] = sort(probs, 'descend');
                    identified = allAcc(identified);

                    % identified(xor(cur.isChargeable, ismember(identified, params.global.chargable))) = [];
                    
                    identified = identified(1);
                    
                    % Magnitude thresholding
                    if sqrt(sum(diff.^2)) < 20
                        % cur.identify.id(pnt) = "WR";
                        % cur.identify.fBias(pnt, :) = diff;
                        continue;
                    end

                    % KNN search
                    accessoryRef = ref(find(ismember({ref.name}, identified)));
                    [~, d] = knnsearch(diff, accessoryRef.feature);
                    dist = mean(d);

                    % Only identify in Attach.
                    if attached.id ~= "NIL"
                        cur.identify.id(pnt) = "NIL";
                        cur.identify.bias(pnt, :) = [0, 0, 0];
                        cur.detected(pnt) = 1;
                        
                        attached.id = "NIL";
                        attached.bias = [0, 0, 0];
                        
                        mag = func_update_diff(mag, gyro.q, params, attached.bias, pnt);
                        mag.mean = movmean(mag.diff, params.pre.movWinSize);

                        cur.detect = func_detect_events(mag, acc, params);
                        idx = find(cur.detect.all(range)) + range(1) - 1;
                        idx = idx(idx>pnt);
                    else % attached.id == "NIL"
                        % if dist > 30
                        %     cur.identify.id(pnt) =  'unknown';
                        % else
                        %     cur.identify.id(pnt) =  identified;
                        % end
                        
                        cur.identify.id(pnt) =  identified;
                        cur.identify.bias(pnt, :) = diff;
                        cur.detected(pnt) = 1;

                        attached.id = identified;
                        attached.bias = diff;
           
                        mag = func_update_diff(mag, gyro.q, params, attached.bias, pnt);
                        mag.mean = movmean(mag.diff, params.pre.movWinSize);

                        cur.detect = func_detect_events(mag, acc, params);
                        idx = find(cur.detect.all(range)) + range(1) - 1;
                        idx = idx(idx>pnt);
                    end
                end

            end
            
            % cur.detected = find(cur.detected);
            result.trial(tIdx) = cur;
            tIdx = tIdx + 1;
            
            if params.data.raw
                feature(cnt2).trial(cnt3).rmag = mag;
            else
                feature(cnt2).trial(cnt3).mag = mag;
            end

        end
    end

    fprintf(" end!\n")
end

toc