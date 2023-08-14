function result = func_make_unit_matrix(dataset, nTrain)

if ~exist("nTrain", 'var')
    nDataCur = length(dataset(1).feature);
else
    nDataCur = nTrain;
end


nAcc = length(dataset);

lFeature = 3;


result = [];
result.data = zeros(nAcc * nDataCur, lFeature);
result.label = cell(nAcc * nDataCur, 1);


for cnt = 1:nAcc
    nDatas = length(dataset(cnt).feature);
    nIdx = false(1, nDatas);
    nIdx(randperm(nDatas, nDataCur)) = true;

    cur = dataset(cnt).feature(nIdx, :);
    
    range = (cnt - 1) * nDataCur + (1:nDataCur);
    result.data(range, :) = [vertcat(cur)];   
    result.label(range) = repmat({dataset(cnt).name}, nDataCur, 1);
end
end