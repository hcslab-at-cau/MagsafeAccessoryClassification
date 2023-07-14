function [res, inferredMag] = func_extract_feature(mag, gyro, range, interval, rate)
    l = min([length(mag), length(gyro)]);

    if range(1) < 2
        range = 2:range(end);
    end

    if range(end) > l
        range = range(1):l;
    end

    refMag = mag(range(1), :);

    for t = range(1):interval:range(end)
        lIdx = t+ interval-1;

        if lIdx > range(end)
           lIdx = range(end);
        end
        
        euler = sum(gyro(t:lIdx, :)) * 1/rate;

        if t == lIdx
            euler = gyro(t, :) * 1/rate;
        end


        rotm = eul2rotm(euler, 'XYZ');

        inferredMag =(rotm\refMag')';
        refMag= inferredMag;

        if lIdx == range(end)
            break;
        end
    end

    res = mag(range(end), :) - inferredMag;
end

