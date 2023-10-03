detected = struct();

params.detect.magTh = 2;
params.detect.diffTh = 5;

params.detect.initRange = params.pre.cRange;

params.detect.margin = params.data.rate * 0.1 * 2 + 1;
params.detect.minDist = params.data.rate * 1;

tic
for cnt = 1:length(data) 
    for cnt2 = 1:length(data(cnt).trial)
        mag = data(cnt).trial(cnt2).rmag;
        range = 1:min([length(mag.magnitude), length(mag.diff)]);

        cur = struct();
        % Filter 1 : the magnitude of mag should be large  enough
        cur.mag = (mag.magnitude(range) > params.detect.magTh) .* mag.magnitude;
        [vals, locs] = findpeaks(cur.mag, 'MinPeakDistance', params.detect.minDist);

        cur.mag(:) = 0;
        cur.mag(locs) = vals;
               
        % Filter 2 : the diff between mag and gyro should be large enough               
        cur.diff = mag.diff(range, :) > params.detect.diffTh;

        cur.all = cur.mag & movsum(cur.diff, params.detect.margin);        
        detected(cnt).trial(cnt2) = cur;
    end
end
toc

%%
func_plot_detected(data, detected, 6, 2);