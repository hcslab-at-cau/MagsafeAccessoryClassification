function [cur] = func_detect_events(mag, params)

range = 1:min([length(mag.magnitude), length(mag.diff)]);

cur = struct();
% Filter 1 : the magnitude of mag should be large enough
cur.mag = (mag.magnitude(range) > params.detect.magTh) .* mag.magnitude;
[vals, locs] = findpeaks(cur.mag, 'MinPeakDistance', params.detect.minDist);

cur.mag(:) = 0;
cur.mag(locs) = vals;
       
% Filter 2 : the diff between mag and gyro should be large enough               
cur.diff = mag.diff(range, :) > params.detect.diffTh;

cur.all = cur.mag & movsum(cur.diff, params.detect.margin);    

end