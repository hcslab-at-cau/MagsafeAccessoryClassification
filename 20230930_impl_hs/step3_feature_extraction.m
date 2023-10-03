tic
params.feature.path = 'features/jaemin3_p2p.mat';
params.feature.nVal = 10;
params.feature.nTotal = 50;
params.feature.nSub = floor(params.feature.nTotal / (params.feature.nVal));

params.feature.mType = 'rmag';

load(params.feature.path);
objects = feature;
objects(~ismember({objects(:).name}, {data.name})) = [];

for cnt = 1:length(objects)
    objects(cnt).value = objects(cnt).feature;   
    objects(cnt).feature = zeros(params.feature.nVal, 3);

    for cnt2 = 1:params.feature.nVal
        range = (cnt2 - 1) * params.feature.nSub + (1:params.feature.nSub);
        if params.feature.nSub > 1
            objects(cnt).feature(cnt2, :) = mean(objects(cnt).value(range, :));
        else
            objects(cnt).feature(cnt2, :) = objects(cnt).value(range, :);
        end
    end
end

feature = struct();
for cnt = 1:length(data)
    for cnt2 = 1:length(data(cnt).trial)
        mag = data(cnt).trial(cnt2).(params.feature.mType);
        gyro = data(cnt).trial(cnt2).gyro;

        for cnt3 = 1:length(objects)
            for cnt4 = 1:params.feature.nVal
                sample = (mag.raw - objects(cnt3).feature(cnt4, :) - mag.B) * mag.A;            
                inferred = [sample(1, :); quatrotate(gyro.q(2:end, :), sample(1:end - 1, :))];

                feature(cnt).trial(cnt2).obj((cnt3 - 1) * params.feature.nVal + cnt4, :) = ...
                    sum((sample - inferred).^2, 2);
            end
        end
        feature(cnt).trial(cnt2).obj(end + 1, :) = sum(mag.diff.^2, 2);
    end
end
toc