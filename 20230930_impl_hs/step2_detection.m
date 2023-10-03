detected = struct();

params.detect.magTh = 5;
params.detect.diffTh = 20;

params.detect.initRange = params.pre.cRange;

params.detect.margin = params.data.rate * 0.1 * 2 + 1;
params.detect.minDist = params.data.rate * 1;

tic
for cnt = 1:length(data) 
    for cnt2 = 1:length(data(cnt).trial)
        mag = data(cnt).trial(cnt2).rmag;
        acc = data(cnt).trial(cnt2).acc;
        gyro = data(cnt).trial(cnt2).gyro;

        range = 1:min([length(mag.magnitude), length(mag.diff)]);

        cur = struct();
        % Filter 1 : the magnitude of mag should be large  enough
        cur.filter.mag = mag.magnitude(range) > params.detect.magTh;
        [~, locs] = findpeaks(mag.magnitude(range), 'MinPeakDistance', params.detect.minDist);
        tmp = cur.filter.mag;        
        cur.filter.mag = zeros(size(cur.filter.mag));
        cur.filter.mag(locs) = tmp(locs);
               
        % Filter 2 : the diff between mag and gyro should be large enough               
        cur.filter.diff = sum(mag.diff(range, :).^2, 2) > params.detect.diffTh;

        cur.filter.all = cur.filter.mag & movsum(cur.filter.diff, params.detect.margin);        
        detected(cnt).trial(cnt2) = cur;
    end
end
toc

%%
func_plot_detected(data, detected, 3, 1);