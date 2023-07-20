
% feature = featureUnit;
% feature = featureRange;
feature = featureRangeRange;

values = struct();
values2 = struct();

for cnt = 1:length(feature)
    value = [];
    value2 = [];
    values(cnt).name = feature(cnt).name;
    values2(cnt).name = feature(cnt).name;
    nTrials = length(feature(cnt).trial);

    for cnt2 = 1:nTrials
        cur = feature(cnt).trial(cnt2).cur;
        for cnt3 = 1:length(cur)
            if usingGroundTruth == true
                value = [value;cur(cnt3).attach];
                value2 = [value2;cur(cnt3).detach];
            else
                value = [value;cur(cnt3).diff(1, :)];
                value2 = [value2;cur(cnt3).diff(2, :)];
            end
        end 
    end
    values(cnt).feature = value;
    values2(cnt).feature = value2;
end



dataStatistic = struct('name', {}, 'mean_x', {}, 'mean_y', {}, 'mean_z', {}, 'var_x',{},'var_y',{},'var_z',{});
% dataStatistic = struct();
% varData = zeros(length(values), 3);
accName = values(:).name;
axis = {'x', 'y', 'z'};

for cnt = 1:length(values)
    dataStatistic(cnt).name = values(cnt).name;
    for cnt2 = 1:3
        % varData(cnt, cnt2) = var(values(cnt).feature(:, cnt2));
        % disp(['var', '_', axis(cnt2)])
        dataStatistic(cnt).(['var', '_', axis{cnt2}]) = var(values(cnt).feature(:, cnt2));
        dataStatistic(cnt).(['mean', '_', axis{cnt2}]) = mean(values(cnt).feature(:, cnt2));
    end
end