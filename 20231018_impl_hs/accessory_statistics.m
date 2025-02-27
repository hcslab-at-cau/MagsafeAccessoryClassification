% ref = load('features/ref2_1_99.mat');
% ref = ref.feature;

means = [];
vars = [];

for cnt = 1:length(ref)
    means(end + 1, :) = mean(ref(cnt).feature);
    vars(end + 1, :) = var(ref(cnt).feature);
end

colNames = {'mean X', 'mean Y', 'mean Z', 'var X', 'var Y', 'var Z'};

table = array2table([means, vars], ...
    "RowNames", {ref.name}, "VariableNames",colNames);

disp(table)