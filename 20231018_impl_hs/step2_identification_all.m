%% Identify MagSafe accessories
params.identify.nTotal = length(data(1).trial);
params.identify.nTrain = params.identify.nTotal * 0.2;
params.identify.nTest = params.identify.nTotal - params.identify.nTrain;
allAcc = [params.global.all, 'NIL'];

result = struct();
tIdx = 1;
tic

for cnt = 1:params.identify.nRepeat    
    if rem(cnt, 10) == 0
        disp(cnt)
        toc
    end
    train = ref;
    % train = struct();
    % 
    % for cnt2 = 1:length(mdl.ClassNames)
    %     name = cell2mat(mdl.ClassNames(cnt2));
    %     train(cnt2).name = name;
    %     train(cnt2).isChargeable = func_isChargeable(name);
    % end

    % if params.ref.self
    %     trainIdx = false(1, params.identify.nTotal);
    %     trainIdx(randperm(params.identify.nTotal, params.identify.nTrain)) = true;
    % 
    %     for cnt2 = 1:length(train)
    %         train(cnt2).feature(~trainIdx, :) = [];
    %         feature(cnt2).trial(trainIdx) = [];
    %     end
    % end

    for cnt2 = 1:params.data.nObjects
        for cnt3 = 1:length(feature(cnt2).trial)
            cur = struct();
            cur.name = data(cnt2).name;
            cur.class = find(cellfun('isempty', strfind({data.name}, cur.name)) == 0);
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

            cur.identify.id = strings(length(cur.detect.all), 1);
            cur.identify.bias = zeros(length(cur.detect.all), 3);
            cur.identify.fBias = zeros(length(cur.detect.all), 3);
            for cnt4 = 1:size(cur.event, 1)
                range = max(1, cur.event(cnt4, 1) - params.identify.testMargin): ...
                    min(length(cur.detect.all), cur.event(cnt4, 2) + params.identify.testMargin);
                idx = find(cur.detect.all(range)) + range(1) - 1;

                attached.id = "NIL";
                attached.bias = [0, 0, 0];

                while ~isempty(idx)

                    pnt = idx(1);
                    idx = idx(2:end);                           

                    diff = func_compute_bias_margin(mag, gyro, attached.bias, pnt, ...
                       params, params.identify.prc, false, attached.id ~= "NIL");    

                    err = zeros(params.global.nObjects + 1, 1);
                    for cnt6 = 1:length(train)
                        tmp = sqrt(sum((train(cnt6).feature - diff).^2, 2));
                        err(cnt6) = mean(rmoutliers(tmp, 'percentiles', params.identify.prc));
                    end
                    err(end) = sqrt(sum(diff.^2));

                    [~, identified] = sort(err);
                    identified = allAcc(identified);
                    
                    % For test1 : Only identify in Attach.
                    if attached.id ~= "NIL"
                        cur.identify.id(pnt) = "NIL";                                                
                        cur.identify.bias(pnt, :) = diff; 

                        attached.id = "NIL";
                        attached.bias = diff;

                        [mag.diff(pnt:end, :), mag.inferred(pnt:end, :)] = func_calc_diff(mag.calibrated(pnt:end, :) - attached.bias, gyro.q(pnt:end, :));
                        mag.mean = movmean(mag.diff, params.pre.movWinSize);

                        cur.detect = func_detect_events(mag, acc, params);
                        idx = find(cur.detect.all(range)) + range(1) - 1;
                        idx = idx(idx>pnt);

                        continue;
                    end

                    if identified(1) == "NIL"
                        if attached.id == "NIL"
                            cur.identify.id(pnt) = "WR";
                            cur.identify.fBias(pnt, :) = diff;
                        else
                            cur.identify.id(pnt) = identified(1);                                                
                            cur.identify.bias(pnt, :) = diff; 

                            attached.id = identified(1);
                            attached.bias = diff;

                            [mag.diff(pnt:end, :), mag.inferred(pnt:end, :)] = func_calc_diff(mag.calibrated(pnt:end, :) - attached.bias, gyro.q(pnt:end, :));
                            mag.mean = movmean(mag.diff, params.pre.movWinSize);

                            cur.detect = func_detect_events(mag, acc, params);
                            idx = find(cur.detect.all(range)) + range(1) - 1;
                            idx = idx(idx>pnt);
                        end
                    else
                        identified(identified == "NIL") = [];     
                        identified(xor(cur.isChargeable, ismember(identified, params.global.chargable))) = [];

                        identified = identified(1);

                        if attached.id == "NIL"
                            cur.identify.id(pnt) = identified;
                            cur.identify.bias(pnt, :) = diff;

                            attached.id = identified;
                            attached.bias = diff;

                            [mag.diff(pnt:end, :), mag.inferred(pnt:end, :)] = func_calc_diff(mag.calibrated(pnt:end, :) - attached.bias, gyro.q(pnt:end, :));
                            mag.mean = movmean(mag.diff, params.pre.movWinSize);

                            cur.detect = func_detect_events(mag, acc, params);
                            idx = find(cur.detect.all(range)) + range(1) - 1;
                            idx = idx(idx>pnt);
                        else
                            cur.identify.id(pnt) = "WR";
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