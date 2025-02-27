function [] = func_plot_scatter(features, selection)

features = features(ismember({features.name}, selection));

fig = figure(20);
set(fig, 'Renderer', 'painters')
set(0, 'Units', 'inches')
fig.Alphamap = 



fig.Position(1:2) = [100, 200]
clf

labels = {};

length(features)

for accId = 1:length(features)
    p = features(accId).feature;
    labels{end + 1} =  features(accId).name;

    % p = rmoutliers(p, 'percentiles', [10, 90]);
    
    
    if accId > 7
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

end