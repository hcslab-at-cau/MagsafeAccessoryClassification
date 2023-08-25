if ~strcmp(datasetName, 'Rotation_feature_dataset')
    return;
end

rotationFeatures = struct();
rate = 100;
varThreshold = 0.25;
interval = 5;

for cnt = 1:length(data)
    nTrials = length(data(cnt).trial);
    rotationFeatures(cnt).name = data(cnt).name; 

    for cnt2 = 1:nTrials
        unitData = data(cnt).trial(cnt2);
        mag = unitData.mag;
        gyro = unitData.gyro;
        click = unitData.detect.sample(1);
        start = click - 200;
        
        ref = mag.sample(start, :);
        refMag = ref;
        features = [];
        filtered = [];

        for t = start + 1:length(mag.sample)
            euler = gyro.sample(t, :) * 1/rate;
            rotm = eul2rotm(euler, 'XYZ');
        
            refMag = (rotm\(refMag)')';

            if t > click
                tmp = mag.sample(t, :) - refMag;
                features(end + 1, :) = tmp;
            end
        end

        for cnt3 = interval + 1:length(features)-interval
            range = cnt3 + (-interval:interval);
            v = var(features(range, :));

            if rssq(v) > varThreshold
                filtered(end + 1, :) = features(cnt3, :);
            end
        end

        rotationFeatures(cnt).trial(cnt2).feature = features;
        rotationFeatures(cnt).trial(cnt2).filtered = filtered;
    end
end

%% plot rotation features
values = struct();

for cnt = 1:length(rotationFeatures)
    value = [];
    values(cnt).name = rotationFeatures(cnt).name;
    nTrials = length(rotationFeatures(cnt).trial);

    for cnt2 = 1:nTrials
        cur = rotationFeatures(cnt).trial(cnt2);
        for cnt3 = 1:length(cur)
            value = [value;cur.filtered];
        end 
    end
    values(cnt).feature = value;
end


label = [];
for cnt = 1:length(values)
    label = strvcat(label, [values(cnt).name]);
end

fig = figure(25);
fig.Position(1:4) = [400, 400, 800, 700];
clf


for cnt = 1:length(values)
    p = values(cnt).feature;
    
    if cnt > 6
        scatter3(p(:,1), p(:,2), p(:,3), 'filled');
    else
        scatter3(p(:,1), p(:,2), p(:,3));
    end
    hold on
end

legend(label)
xlabel('x')
ylabel('y')
zlabel('z')

return;
%% Save feature
func_save_feature(values, ['jaemin1', '_rotation'])