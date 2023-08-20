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

    if nDatas < nDataCur
        nIdx(randperm(nDatas, nDatas)) = true;
        curData = dataset(cnt).feature(nIdx, :);
        diffIdx = length(abs(length(nIdx) - nDatas));
        curData = [curData;  NaN(diffIdx,3,'single')];

        curDataLabel = [repmat({dataset(cnt).name}, nDatas, 1); repmat({'undefined'}, diffIdx, 1)];
    else
        nIdx(randperm(nDatas, nDataCur)) = true;
        curData = dataset(cnt).feature(nIdx, :);
        curDataLabel = repmat({dataset(cnt).name}, nDataCur, 1);
    end
    
    range = (cnt - 1) * nDataCur + (1:nDataCur);
    result.data(range, :) = [vertcat(curData)];
    result.label(range) = curDataLabel;
end

% Flush NaN
k = result.data;
k(any(isnan(k), 2), :) = [];
result.data = k;

result.label = result.label(~strcmp(result.label, 'undefined'));
end