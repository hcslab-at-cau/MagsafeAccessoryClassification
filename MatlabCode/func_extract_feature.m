function [res, refMag] = func_extract_feature(mag, gyro, range, status)
    % status == false means accessory status is detached
    rate = 100;
    
    l = min([length(mag), length(gyro)]);

    if range(1) < 2
        range = 2:range(end);
    end

    if range(end) > l
        range = range(1):l;
    end

    if status
        range = flip(range);
    end

    refMag = mag(range(1), :);

    for k = 2:length(range)
        t = range(k);
        euler = gyro(t, :) * 1/rate;

        if status
            euler = -euler;
        end

        rotm = eul2rotm(euler, 'XYZ');

        refMag =(rotm\refMag')';
    end

    res = mag(range(end), :) - refMag;
end

