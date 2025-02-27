function [diff, inferred, magnitude, rmOri] = func_calc_diff(calibrated, q, params)

inferred = [calibrated(1, :); ...
    quatrotate(q(2:end, :), calibrated(1:end - 1, :))];              

diff = sqrt(sum((inferred - calibrated).^2, 2));
diffValue = calibrated - inferred;

rmOri = zeros(length(calibrated), 3);


rmOri(1, :) = calibrated(1, :);
for cnt = 2:length(rmOri)
    rmOri(cnt, :) = rmOri(cnt-1, :) + diffValue(cnt, :);
end

magnitude = sqrt(sum(filtfilt(params.pre.fHB, params.pre.fHA, rmOri).^2, 2));

end