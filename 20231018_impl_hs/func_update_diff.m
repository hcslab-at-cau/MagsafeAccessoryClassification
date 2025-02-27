function mag = func_update_diff(mag, q, params, bias, pnt)
calibrated = mag.calibrated - bias;

tmp = mag.inferred(pnt, :);
mag.inferred(pnt:end, :) = [calibrated(pnt, :); ...
    quatrotate(q(pnt+1:end, :), calibrated(pnt:end-1, :))];   

mag.diff(pnt:end, :) = sqrt(sum((mag.inferred(pnt:end, :) - calibrated(pnt:end, :)).^2, 2));

mag.inferred(pnt, :) = tmp;
diffValue = calibrated - mag.inferred;


for cnt = pnt:length(diffValue)
    mag.rmOri(cnt, :) = mag.rmOri(cnt-1, :) + diffValue(cnt, :);
end

magnitude = sqrt(sum(filtfilt(params.pre.fHB, params.pre.fHA, mag.rmOri).^2, 2));
mag.magnitude(pnt:end, :) = magnitude(pnt:end, :);

end