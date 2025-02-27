function mag = func_update_mag(mag, gyro, range)
calibrated = mag.calibrated(range, :);
q = gyro.q(range, :);

inferred = [mag.calibrated(1, :); ...
    quatrotate(q(2:end, :), calibrated(1:end - 1, :))];              

diff = sqrt(sum((inferred - calibrated).^2, 2));
diffValue = inferred - calibrated;

rmOri = zeros(length(calibrated), 3);
rmOri(1, :) = calibrated(1, :);

for cnt = 2:length(rmOri)
    rmOri(cnt, :) = rmOri(cnt-1, :) + diffValue(cnt, :);
end


mag.inferred(range, :) = inferred;
mag.diff(range, :) = diff;
mag.diffValue(range, :) = diffValue;
mag.rmOri(range, :) = rmOri;

end