function [diff] = func_compute_bias(mag, gyro, bias, idx, searchRange, featureRange, prc)

[~, src.pts]= min(mag.mean(idx + (-searchRange:-1)));
src.pts = src.pts + (idx - searchRange + 1);
src.pts = src.pts + (-featureRange:featureRange);

[~, dst.pts]= min(mag.mean(idx + (1:searchRange)));
dst.pts = dst.pts + idx;
dst.pts = dst.pts + (-featureRange:featureRange);

src.mag = mag.calibrated(src.pts, :) - bias;
src.q = gyro.cumQ(src.pts, :);

dst.mag = mag.calibrated(dst.pts, :);
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