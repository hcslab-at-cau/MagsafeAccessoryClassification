%% Identify MagSafe accessories
params.detect.magTh = .5;
params.detect.diffTh = 2;

params.detect.margin = params.data.rate * 0.1 * 2 + 1;
params.detect.minDist = params.data.rate * 1;

params.identify.testMargin = params.data.rate * 3;

params.identify.searchRange = params.data.rate * .75;
params.identify.featureRange = params.data.rate * .1;
params.identify.prc = [10, 90];

params.identify.nTotal = length(data(1).trial);
params.identify.nTrain = params.identify.nTotal * 0.5;
params.identify.nTest = params.identify.nTotal - params.identify.nTrain;

if params.ref.self 
    params.identify.nRepeat = 10;
else
    params.identify.nRepeat = 1;
end

result = struct();
tIdx = 1;
tic
for cnt = 1:params.identify.nRepeat    
    if rem(cnt, 10) == 0
        disp(cnt)
        toc
    end
    train = ref;
    test = feature;

    if params.ref.self
        trainIdx = false(1, params.identify.nTotal);
        trainIdx(randperm(params.identify.nTotal, params.identify.nTrain)) = true;
    
        for cnt2 = 1:length(train)
            train(cnt2).feature(~trainIdx, :) = [];
            test(cnt2).trial(trainIdx) = [];
        end
    end

    for cnt2 = 1:params.data.nObjects
%     for cnt2 = 2
        for cnt3 = 1:length(test(cnt2).trial)
            cur = struct();
            cur.name = data(cnt2).name;
            cur.class = find(cellfun('isempty', strfind({train.name}, cur.name)) == 0);
            cur.isChargeable = func_isChargeable(cur.name);

            mag = test(cnt2).trial(cnt3).rmag;
            gyro = test(cnt2).trial(cnt3).gyro;

            cur.event = test(cnt2).trial(cnt3).event.sample;
            cur.event = reshape(cur.event, 2, length(cur.event)/2)';

            cur.detect = func_detect_events(mag, params);

            cur.identify.id = zeros(1, length(cur.detect.all));
            cur.identify.bias = zeros(length(cur.detect.all), 3);
            for cnt4 = 1:size(cur.event, 1)
                range = max(1, cur.event(cnt4, 1) - params.identify.testMargin): ...
                    min(length(cur.detect.all), cur.event(cnt4, 2) + params.identify.testMargin);
                idx = find(cur.detect.all(range)) + range(1) - 1;

                attached.id = params.data.nObjects + 1;
                attached.bias = [0, 0, 0];
                for cnt5 = idx'
                    diff = func_compute_bias(mag, gyro, attached.bias, cnt5, ...
                       params.identify.searchRange, params.identify.featureRange, params.identify.prc);                               
                    
                    err = zeros(params.data.nObjects + 1, 1);
                    for cnt6 = 1:length(train)
                        tmp = sqrt(sum((train(cnt6).feature - diff).^2, 2));
                        err(cnt6) = mean(rmoutliers(tmp, 'percentiles', params.identify.prc));
                    end
                    err(end) = sqrt(sum(diff.^2));
 
                    [~, identified] = sort(err);

                    if identified(1) == params.data.nObjects + 1
                        if attached.id == params.data.nObjects + 1
                            cur.identify.id(cnt5) = -1;
                        else
                            cur.identify.id(cnt5) = identified(1);                                                
                            cur.identify.bias(cnt5, :) = diff; 
                            
                            attached.id = identified(1);
                            attached.bias = diff;
                        end
                    else
                        identified(identified == params.data.nObjects + 1) = [];                
                        identified([train(identified).isChargeable] ~= cur.isChargeable) = [];
                        identified = identified(1);
    
                        if attached.id == params.data.nObjects + 1
                            cur.identify.id(cnt5) = identified;
                            cur.identify.bias(cnt5, :) = diff;
                            
                            attached.id = identified;
                            attached.bias = diff;
                        else
                            cur.identify.id(cnt5) = -1;
                        end
                    end
                end
            end

            result.trial(tIdx) = cur;
            tIdx = tIdx + 1;
        end
    end
end