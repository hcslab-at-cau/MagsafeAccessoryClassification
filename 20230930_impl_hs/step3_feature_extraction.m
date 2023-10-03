tic

feature = struct();
for cnt = 1:length(data)
    for cnt2 = 1:length(data(cnt).trial)
        if params.data.newApp == true
            mag = data(cnt).trial(cnt2).rmag;
        else
            mag = data(cnt).trial(cnt2).mag;
        end

        idx = 1;
        feature(cnt).trial(cnt2).ref = zeros(length(ref) * params.ref.nSub + 1, length(mag.raw));
        for cnt3 = 1:length(ref)
            for cnt4 = 1:params.ref.nSub
                calibrated = (mag.raw - ref(cnt3).feature(cnt4, :) - mag.B) * mag.A;
                feature(cnt).trial(cnt2).ref(idx, :) = ...
                    func_calc_diff(calibrated, data(cnt).trial(cnt2).gyro.q);
                idx = idx + 1;
            end
        end
        feature(cnt).trial(cnt2).ref(end, :) = mag.diff;
    end
end
toc