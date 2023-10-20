function [raw, calibrated, A, B] = func_calib_mag(raw, calib, isRaw)

if isRaw == true
    [A, B, ~] = magcal(calib);
else
    A = 1;
    B = 0;
end

calibrated = (raw - B) * A;          

end