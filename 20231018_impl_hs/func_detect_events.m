function [cur] = func_detect_events(mag, acc, params)
range = 1:min([length(mag.magnitude), length(mag.diff)]);

cur = struct();
% Filter 1 : the magnitude of mag should be large enough
% cur.mag = (mag.magnitude(range) > params.detect.magTh) .* mag.magnitude;
% [vals, locs] = findpeaks(cur.mag, 'MinPeakDistance', params.detect.minDist);

cur.mag = (mag.magnitude(range) > params.detect.magTh) .* mag.magnitude;
[vals, locs] = findpeaks(cur.mag, 'MinPeakDistance', params.detect.minDist);

cur.mag(:) = 0;
cur.mag(locs) = vals;

cur.all = cur.mag;

% Filter 2 : Magnitude of accelerometer
cur.acc = acc.magnitude > 0.01;

cur.all = cur.mag & movsum(cur.acc, params.detect.margin);

end