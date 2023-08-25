% valueNames = {'jaemin3_p2p', 'jaemin4_p2p', 'jaemin5_p2p', 'jaemin6_p2p', ...
% 'jaemin7_p2p', 'jaemin8_p2p', 'jaemin9_p2p', 'jaemin1_rotation', 'insu1_p2p', 'test_p2p'};
% 
% names = {'jaemin3', 'jaemin4', 'jaemin5', 'jaemin6', 'jaemin7', 'jaemin8', 'jaemin9', 'jaemin1', 'insu1', 'jaemin'};

valueNames = {'jaemin1_rotation','test_p2p'};

names = {'jaemin1', 'jaemin'};
% 
% valueNames = {'orientation_p2p'};
% names = {'jaemin9'};

includeTable = {'holder3'};

figure(5)
clf
hold on

labels = [];

colors = rand(length(valueNames), 3);
% oldColor = [0.2, 0.5, 0.8];
for cnt = 1:length(valueNames)
    
    % values = func_load_feature([char(names(cnt)), '_p2p']);
    values = func_load_feature(char(valueNames(cnt)));
    accNames = {values.name};

    values = values(ismember(accNames, includeTable));

    for cnt2 = 1:length(values)
        labels = strvcat(labels, [values(cnt2).name, '-', char(names(cnt))]);
    end
    % labels = strvcat(labels, label);
    c = colors(cnt, :);

    for cnt2 = 1:length(values)
        p = values(cnt2).feature;
        
        
        if cnt > 6
            scatter3(p(:,1), p(:,2), p(:,3), 'filled', 'MarkerFaceColor', c, 'MarkerEdgeColor', c);
        else
            scatter3(p(:,1), p(:,2), p(:,3), 'MarkerFaceColor', c, 'MarkerEdgeColor', c);
        end
        hold on
    end
end


% for cnt2 = 1:cnt
%     randomColor = rand(1, 3);
%     range = 1 + interval*(cnt2-1):interval*cnt2;
%     p = features(range, :);
%     scatter3(p(:,1), p(:,2), p(:,3), 'filled', 'MarkerFaceColor', randomColor, 'MarkerEdgeColor', randomColor);
% end

% labels = strvcat(labels, char({'1', '2', '3', '4'}));

legend(labels)
xlabel('x')
ylabel('y')
zlabel('z')