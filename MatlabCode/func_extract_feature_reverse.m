function [res, inferredMag] = func_extract_feature_reverse(mag, gyro, range, interval, rate)
    l = min([length(mag), length(gyro)]);
    interval = -interval;

    if range(1) < 1
        range = 1:range(end);
    end

    if range(end) >= l
        range = range(1):l-1;
    end

    range = range(end):interval:range(1);

    refMag = mag(range(1), :);

    for t = range
        lIdx = t+ interval+1;

        if lIdx < range(end)
           lIdx = range(end);
        end
        
        euler = -sum(gyro(lIdx:t, :)) * 1/rate;

        if t == lIdx
            euler = -gyro(t, :) * 1/rate;
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

