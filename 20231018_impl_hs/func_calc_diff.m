function [diff, inferred] = func_calc_diff(calibrated, q)

inferred = [calibrated(1, :); ...
    quatrotate(q(2:end, :), calibrated(1:end - 1, :))];              

diff = sqrt(sum((inferred - calibrated).^2, 2));                    

end