function result = func_make_unit_matrix(dataset)

nAcc = length(dataset);

lFeature = 3;
nTrainCur = length(dataset(1).feature);

result = [];
result.data = zeros(nAcc * nTrainCur, lFeature);
result.label = cell(nAcc * nTrainCur, 1);


for cnt = 1:nAcc
    nDatas = length(dataset(cnt).feature);

    cur = dataset(cnt).feature;
    
    range = (cnt - 1) * nDatas + (1:nDatas);
    result.data(range, :) = [vertcat(cur)];   
    result.label(range) = repmat({dataset(cnt).name}, nTrainCur, 1);
end
end