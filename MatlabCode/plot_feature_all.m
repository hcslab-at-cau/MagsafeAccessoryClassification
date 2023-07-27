

valueNames = {'jaemin3_p2p_wSize', 'jaemin4_p2p_wSize', 'jaemin5_p2p_wSize', 'jaemin6_p2p_wSize', ...
'jaemin7_p2p_wSize', 'jaemin8_p2p'};

names = {'jaemin3', 'jaemin4', 'jaemin5', 'jaemin6', 'jaemin7', 'jaemin8'};


includeTable = {'holder4'};

figure(1)
clf
hold on

labels = [];

for cnt = 1:length(valueNames)
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
        scatter3(p(:,1), p(:,2), p(:,3));
    end
    hold on
end

legend(labels)
xlabel('x')
ylabel('y')
zlabel('z')