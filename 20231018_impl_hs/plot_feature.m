
% load("features/ref2+3.mat");
load("features/orientation2.mat")
excepts = {'wallet3', 'holder3'};
chargable = {'batterypack1', 'charger1', 'charger2', 'charger3', 'holder2', ... 
            'holder3', 'holder4'};

feature(ismember({feature.name}, excepts)) = [];
feature(ismember({feature.name}, chargable)) = [];

figure(1)
clf
labels = {};

for accId = 1:length(feature)
    p = feature(accId).feature;
    labels{end + 1} =  feature(accId).name;
    % p = rmoutliers(p, 'percentiles', [10, 90]);
    
    if accId > 6
        scatter3(p(:,1), p(:,2), p(:,3), 'filled');
    else
        scatter3(p(:,1), p(:,2), p(:,3));
    end
    hold on
end

legend(labels)
xlabel('x')
ylabel('y')
zlabel('z')
%%

a = load("features/orientation2.mat");
b = load("features/orientation2.mat");

select = {'holder4', 'charger3'};
a = a.feature(ismember({a.feature.name}, select));
b = b.feature(ismember({b.feature.name}, select));

legends = {};

figure(5)
clf
labels = {};

for cnt = 1:length(a)
    s = a(cnt).feature;

    hold on
    scatter3(s(:,1), s(:,2), s(:,3));
    legends{end + 1} = ['a-', a(cnt).name];
end

for cnt = 1:length(b)
    s = b(cnt).feature;

    hold on
    scatter3(s(:,1), s(:,2), s(:,3));
    legends{end + 1} = ['b-', b(cnt).name];
end


% a = a.feature;
% b = b.feature;
% 
% % b = b((k-1)*5+1:k*5, :);
% 
% hold on
% scatter3(a(:,1), a(:,2), a(:,3));
% % for cnt = 1:length(b)/5
% %     range = ((cnt-1) * 5 + 1):(cnt)*5;
% %     s = b(range, :);
% %     scatter3(s(:,1), s(:,2), s(:,3));
% % end
% 
% scatter3(b(:,1), b(:,2), b(:,3));

% legend({'attach with interval', 'attach and rotate'})
legend(legends)
xlabel('x')
ylabel('y')
zlabel('z')
%%
accId = 1;
nTrial = length(feature(accId).feature)/5;
colors = rand(nTrial, 3);
labels = {};

figure(2)
clf

for cnt = 1:nTrial
    start = (cnt-1)*5 + 1;
    p = feature(accId).feature(start:start+4, :);
    c = colors(cnt, :);
    labels{end + 1} = num2str(cnt);

    if cnt > 6
        scatter3(p(:,1), p(:,2), p(:,3), 'filled', 'MarkerFaceColor', c, 'MarkerEdgeColor', c);
    else
        scatter3(p(:,1), p(:,2), p(:,3), 'MarkerFaceColor', c, 'MarkerEdgeColor', c);
    end
    hold on
end

legend(labels)
xlabel('x')
ylabel('y')
zlabel('z')
title(feature(accId).name)
%% Figure for orientation feature

features = load("features/orientation3.mat");
features = features.feature;

func_plot_scatter(features, {'charger1'})