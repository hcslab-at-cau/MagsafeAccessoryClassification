name = 'jaemin1_rotation';
values = func_load_feature(name);
featureFigNum = 2;

% only plot includeTable
includeTable = {'holder3'};

accNames = {values.name};

tmpFeature = struct();

for cnt = 1:length(includeTable)
    tmp = values(contains(accNames, char(includeTable(cnt))));
    tmpFeature(cnt).name = tmp.name;
    tmpFeature(cnt).feature = tmp.feature;
end 

values = tmpFeature;


label = [];
for cnt = 1:length(values)
    label = strvcat(label, [values(cnt).name, '_', name]);
end

figure(featureFigNum)
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


xlabel('x')
ylabel('y')
zlabel('z')

hold on
%% For two
name = 'jaemin3_p2p';
values2 = func_load_feature(name);

accNames = {values2.name};
tmpFeature = struct();

for cnt = 1:length(includeTable)
    tmp = values2(contains(accNames, char(includeTable(cnt))));
    tmpFeature(cnt).name = tmp.name;
    tmpFeature(cnt).feature = tmp.feature;
end 

values2 = tmpFeature;

label2 = [];
for cnt = 1:length(values2)
    label2 = strvcat(label2, [values2(cnt).name, '_', name]);
end

for cnt = 1:length(values2)
    p = values2(cnt).feature;
    
    if cnt > 6
        scatter3(p(:,1), p(:,2), p(:,3), 'filled');
    else
        scatter3(p(:,1), p(:,2), p(:,3));
    end
    hold on
end
% legend(strvcat(label, label2))
label = strvcat(label, label2);
legend(label)
%% For three
% name = 'orientation_p2p';
% values2 = func_load_feature(name);
% 
% % includeTable = {'holder3'};
% accNames = {values2.name};
% tmpFeature = struct();
% 
% for cnt = 1:length(includeTable)
%     tmp = values2(contains(accNames, char(includeTable(cnt))));
%     tmpFeature(cnt).name = tmp.name;
%     tmpFeature(cnt).feature = tmp.feature;
% end 
% 
% values2 = tmpFeature;
% 
% label3 = [];
% for cnt = 1:length(values2)
%     label3 = strvcat(label3, [values2(cnt).name, '_', name]);
% end
% 
% for cnt = 1:length(values2)
%     p = values2(cnt).feature;
% 
%     if cnt > 6
%         scatter3(p(:,1), p(:,2), p(:,3), 'filled');
%     else
%         scatter3(p(:,1), p(:,2), p(:,3));
%     end
%     hold on
% end
% legend(strvcat(label, label3))