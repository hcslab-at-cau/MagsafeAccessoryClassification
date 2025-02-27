function [diff, src, dst, diffApplied] = func_compute_bias_margin(mag, gyro, bias, idx, params, prc, flag, status)
searchRange = params.identify.searchRange;
featureRange = params.identify.featureRange;
diffApplied = false;

if status == true % Accessory attached 
    searchRangeA = params.identify.baseRange;
    searchRangeB = searchRange;
else
    searchRangeB = params.identify.baseRange;
    searchRangeA = searchRange;
end

[~, src.pts]= min(mag.mean(idx + (-searchRangeA:-1)));
src.pts = src.pts + (idx - searchRangeA + 1);
% src.pts = idx - searchRangeA;
src.pts = src.pts + (-featureRange:featureRange);

[~, dst.pts]= min(mag.mean(idx + (1:searchRangeB)));
dst.pts = dst.pts + idx;
% dst.pts = idx + searchRangeB;
dst.pts = dst.pts + (-featureRange:featureRange);

if dst.pts(end) > length(mag.calibrated)
    dst.pts = dst.pts(1):length(mag.calibrated);
end

src.mag = mag.calibrated(src.pts, :) - bias;
src.q = gyro.cumQ(src.pts, :);

if flag
    dst.mag = mag.calibrated(dst.pts, :) - bias;
else
    dst.mag = mag.calibrated(dst.pts, :);
end

dst.q = gyro.cumQ(dst.pts, :);

diff = [];
for cnt = 1:length(src.pts)
    rotated = quatrotate(quatinv(src.q(cnt, :)), src.mag(cnt, :));
    rotated = quatrotate(dst.q, rotated);
    % rotated = src.mag(cnt, :);

    diff = [diff; dst.mag - rotated];
end

diff = rmoutliers(diff, 'percentiles', prc);                
diff = mean(diff);

end