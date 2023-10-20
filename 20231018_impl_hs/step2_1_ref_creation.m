%% Identify MagSafe accessories
params.detect.magTh = .5;
params.detect.diffTh = 2.5;

params.detect.margin = params.data.rate * 0.1 * 2 + 1;
params.detect.minDist = params.data.rate * 1;

params.identify.testMargin = params.data.rate * 3;

params.identify.searchRange = params.data.rate * .75;
params.identify.featureRange = params.data.rate * .1;
params.identify.prc = [10, 90];

tic
saved = struct();
for cnt = 1:params.data.nObjects
    class = find(cellfun('isempty', strfind({ref.name}, data(cnt).name)) == 0);
    if isempty(class)
        class = 0;
    end
    saved(cnt).name = data(cnt).name;
    saved(cnt).feature = zeros(length(data(cnt).trial), 3);

    for cnt2 = 1:length(data(cnt).trial)
        cur = struct();        
        cur.feature = zeros(length(data(cnt).trial), 3);

        mag = feature(cnt).trial(cnt2).rmag;      
        gyro = feature(cnt).trial(cnt2).gyro;        
        % Perform individual tests for each attach-detach pair

        detected = func_detect_events(mag, params);

        range = max(1, feature(cnt).trial(cnt2).event.sample(1) - params.identify.testMargin): ...
            feature(cnt).trial(cnt2).event.sample(1);

        idx = find(detected.all(range)) + range(1) - 1;

        if ~isempty(idx)
            saved(cnt).feature(cnt2, :) = func_compute_bias(mag, gyro, [0, 0, 0], idx(1), ...
                params.identify.searchRange, params.identify.featureRange, params.identify.prc);                               
        end
    end
end
toc