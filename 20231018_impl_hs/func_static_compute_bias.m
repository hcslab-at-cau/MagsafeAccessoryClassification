function [diff, src, dst] = func_static_compute_bias(mag, gyro, bias, idx, params, prc, flag, status)
searchRange = params.identify.searchRange;
featureRange = params.identify.featureRange;

if status == true % Accessory attached 
    searchRangeA = params.identify.baseRange;
    searchRangeB = searchRange;
else
    searchRangeB = params.identify.baseRange;
    searchRangeA = searchRange;
end

% [~, src.pts]= min(mag.mean(idx + (-searchRangeA:-1)));
src.pts = max((idx - searchRangeA + 1), featureRange + 1);
src.pts = src.pts + (-featureRange:featureRange);

% [~, dst.pts]= min(mag.mean(idx + (1:searchRangeB)));
dst.pts = min(idx + searchRangeB, length(mag.mean) - featureRange);
dst.pts = dst.pts + (-featureRange:featureRange);

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
    
    diff = [diff; dst.mag - rotated];
end

diff = rmoutliers(diff, 'percentiles', prc);                
diff = mean(diff);
end

