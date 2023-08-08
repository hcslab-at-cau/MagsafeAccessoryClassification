valueNames = {'jaemin3_p2p', 'jaemin4_p2p', 'jaemin5_p2p', 'jaemin6_p2p', ...
'jaemin7_p2p', 'jaemin8_p2p', 'jaemin9_p2p'};

names = {'jaemin3', 'jaemin4', 'jaemin5', 'jaemin6', 'jaemin7', 'jaemin8', 'jaemin9'};
% 
% valueNames = {'orientation_p2p'};
% names = {'jaemin9'};

includeTable = {'griptok2'};

figure(5)
clf
hold on

labels = [];

oldColor = rand(1, 3);
% oldColor = [0.2, 0.5, 0.8];
for cnt = 1:length(valueNames)
    
    % values = func_load_feature([char(names(cnt)), '_p2p']);
    values = func_load_feature(char(valueNames(cnt)));
    accNames = {values.name};

    values = values(ismember(accNames, includeTable));

    label = [];
    for cnt2 = 1:length(values)
        label = strvcat(label, [values(cnt2).name, '-', char(names(cnt))]);
    end
    labels = strvcat(labels, label);

    for cnt2 = 1:length(values)
        p = values(cnt2).feature;
        if cnt > 6
            scatter3(p(:,1), p(:,2), p(:,3), 'filled', 'MarkerFaceColor', oldColor, 'MarkerEdgeColor', oldColor);
        else
            scatter3(p(:,1), p(:,2), p(:,3), 'MarkerFaceColor', oldColor, 'MarkerEdgeColor', oldColor);
        end
        hold on
    end
end

% for rotation features
p = features;

accId = 1;
trialId = 1;

tmp = data(accId).trial(trialId);
mag = tmp.mag;
click = tmp.detect.sample(1);

ranges = click + 100:length(mag.diff);
cnt = 4;
interval = fix(length(ranges)/cnt);


for cnt2 = 1:cnt
    randomColor = rand(1, 3);
    range = 1 + interval*(cnt2-1):interval*cnt2;
    p = features(range, :);
    scatter3(p(:,1), p(:,2), p(:,3), 'filled', 'MarkerFaceColor', randomColor, 'MarkerEdgeColor', randomColor);
end

labels = strvcat(labels, char({'1', '2', '3', '4'}));

legend(labels)
xlabel('x')
ylabel('y')
zlabel('z')