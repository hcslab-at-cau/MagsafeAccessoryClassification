function [raw, calibrated, A, B] = func_calib_mag(raw, isRaw, cRange, A, B)

if nargin < 4
    if isRaw == true
        [A, B, ~] = magcal(raw(cRange, :));
    else
        A = 1;
        B = 0;
    end
end

calibrated = (raw - B) * A;          

end