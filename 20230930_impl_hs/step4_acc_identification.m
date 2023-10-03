%%
params.identify.range = params.data.rate * 0.5 + (1:params.data.rate * 2);
params.identify.margin = params.data.rate * 3;

params.identify.detectGap = params.data.rate * 3;

result = struct();
summary = struct();
summary.acc = zeros(length(data), 2);
summary.nAttach = zeros(length(data), 1);
for cnt = 1:length(data)
    accId = find(cellfun('isempty', strfind({objects.name}, data(cnt).name)) == 0);
    if isempty(accId)
        accId = 0;
    end

    for cnt2 = 1:length(data(cnt).trial)
        dFilter = detected(cnt).trial(cnt2).filter.all;

        groundTruth = data(cnt).trial(cnt2).detect.sample;
        groundTruth = reshape(groundTruth, 2, length(groundTruth)/2)';

        cur = struct();        
        cur.class = accId;
        cur.nAttach = size(groundTruth, 1);
        cur.details = zeros(size(dFilter));
        cur.acc = zeros(1, 2);

        for cnt3 = 1:size(groundTruth, 1)
            range = groundTruth(cnt3, 1) - params.identify.margin: ...
                groundTruth(cnt3, end) + params.identify.margin;
            dIdx = find(dFilter(range));
            dIdx = dIdx + range(1) - 1;

            attachedId = length(objects) + 1;
            for cnt4 = dIdx'
                [~, mIdx] = min(sum(feature(cnt).trial(cnt2).obj(:, cnt4 + params.identify.range), 2));
                mIdx = ceil(mIdx / params.feature.nVal);

                if mIdx == attachedId
                    cur.details(cnt4) = -1;
                elseif attachedId ~= length(objects) + 1 && mIdx ~= length(objects) + 1
                    cur.details(cnt4) = -1;
                else
                    cur.details(cnt4) = mIdx;
                    attachedId = mIdx;
                end
            end

            for cnt4 = 1:2
                range = max(1, groundTruth(cnt3, cnt4) - params.identify.detectGap):...
                min(length(cur.details), groundTruth(cnt3, cnt4));
                if cnt4 == 1 && sum(cur.details(range) == cur.class) > 0
                    cur.acc(cnt4) = cur.acc(cnt4) + 1;
                elseif cnt4 == 2 && sum(cur.details(range) == length(objects) + 1) > 0
                    cur.acc(cnt4) = cur.acc(cnt4) + 1;
                end
            end
        end

        summary.acc(cnt, :) = summary.acc(cnt, :) + cur.acc;
        summary.nAttach(cnt) = summary.nAttach(cnt) + cur.nAttach;

        cur.acc = cur.acc / cur.nAttach;
        result(cnt).trial(cnt2) = cur;
    end
end

summary.acc = summary.acc ./ summary.nAttach;
summary.acc(end + 1, :) = mean(summary.acc);

clf
nRow = length(data);
nCol = length(data(1).trial);
for cnt = 1:length(data)
    for cnt2 = 1:length(data(cnt).trial)
        cur = result(cnt).trial(cnt2);
        subplot(nRow, nCol, (cnt - 1) * nCol + cnt2)
        hold on
        plot(cur.details)
        plot(ones(1, length(cur.details)) * cur.class)
        plot(ones(1, length(cur.details)) * length(objects) + 1)
        title([data(cnt).name, ': ', num2str(cur.acc)])
    end
end