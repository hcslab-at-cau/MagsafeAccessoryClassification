valueNames = {'jaemin3_p2p', 'jaemin4_p2p', 'jaemin5_p2p', 'jaemin6_p2p', ...
'jaemin7_p2p', 'jaemin8_p2p', 'jaemin9_p2p', 'jaemin9_p2p_orient'};

names = {'jaemin3', 'jaemin4', 'jaemin5', 'jaemin6', 'jaemin7', 'jaemin8', 'jaemin9', 'jaemin9'};

includeTable = {'griptok2'};

figure(1)
clf
hold on

labels = [];


oldColor = [0.2, 0.5, 0.8];
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
            disp('hello')
            scatter3(p(:,1), p(:,2), p(:,3), 'MarkerFaceColor', oldColor, 'MarkerEdgeColor', oldColor);
        end
        hold on
    end
end
randomColor = rand(1, 3);

newColor = [0.5, 0.7, 0.1];
labels = strvcat(labels, ['griptok2', '-', 'rotate']);

p = features;
scatter3(p(:,1), p(:,2), p(:,3), 'filled', 'MarkerFaceColor', newColor, 'MarkerEdgeColor', newColor);
hold on


legend(labels)
xlabel('x')
ylabel('y')
zlabel('z')