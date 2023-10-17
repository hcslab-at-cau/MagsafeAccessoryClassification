%% Identify MagSafe accessories
params.identify.featureRange = params.data.rate * 0.5 + (1:params.data.rate * 2);
params.identify.testMargin = params.data.rate * 3;

tic
for cnt = 1:length(result)
    class = find(cellfun('isempty', strfind({ref.name}, data(cnt).name)) == 0);
    if isempty(class)
        class = 0;
    end
    result(cnt).name = data(cnt).name;
    result(cnt).class = class;
    result(cnt).isChargeable = func_isChargeable(result(cnt).name);

    for cnt2 = 1:length(result(cnt).trial)
        cur = struct();        
        cur.tTest = data(cnt).trial(cnt2).detect.sample;
        cur.tTest = reshape(cur.tTest, 2, length(cur.tTest)/2)';
        cur.details = double(result(cnt).trial(cnt2).detect.all);

        % Perform individual tests for each attach-detach pair
        for cnt3 = 1:size(cur.tTest, 1)
            range = max(1, cur.tTest(cnt3, 1) - params.identify.testMargin): ...
                min(length(cur.details), cur.tTest(cnt3, 2) + params.identify.testMargin);
            idx = find(cur.details(range)) + range(1) - 1;

            % Intially nothing attached
            attached = length(ref) + 1; 
            for cnt4 = idx'
                % Find the accessory that minimizes diff errors.
                range = cnt4 + params.identify.featureRange;
                range(range > length(feature(cnt).trial(cnt2).identify)) = [];

                [~, identified] = sort(sum(feature(cnt).trial(cnt2).identify(:, range), 2), 'ascend');
                identified = ceil(identified / params.ref.nSub);
                
                if identified(1) ~= length(ref) + 1
                    identified(identified == length(ref) + 1) = [];                
                    identified([ref(identified).isChargeable] ~= result(cnt).isChargeable) = [];                    
                end
                identified = identified(1);                

                if identified == attached 
                    % False positive if an accessory is not newly attached or detached
                    cur.details(cnt4) = -1;
                elseif attached ~= length(ref) + 1 && identified ~= length(ref) + 1
                    % False positive if an attach event is detected without detaching the existing one
                    cur.details(cnt4) = -1;
                else
                    % Attach or detach events! 
                    cur.details(cnt4) = identified;
                    attached = identified;
                end
            end
        end
        result(cnt).trial(cnt2).identify = cur;
    end
end
toc

%% Plotting detection results
clf
nRow = length(result);
nCol = length(result(1).trial);
for cnt = 1:length(result)
    for cnt2 = 1:length(result(cnt).trial)
        cur = result(cnt).trial(cnt2).identify;
        subplot(nRow, nCol, (cnt - 1) * nCol + cnt2)
        hold on
        plot(cur.details)
        plot(ones(1, length(cur.details)) * result(cnt).class)
        plot(ones(1, length(cur.details)) * length(ref) + 1)
        title(result(cnt).name)
    end
end

% dId = 10;
% tId = 1;
% cur = feature(dId).trial(tId).identify;
% 
% subplot(size(cur, 1) + 1, 1, 1)
% plot(result(dId).trial(tId).identify.details)
% 
% for cnt = 1:size(cur, 1)
%     subplot(size(cur, 1) + 1, 1, cnt + 1)
%     plot(cur(cnt, :))
%     if cnt < size(cur, 1)
%         title([data(dId).name, ' w/ ', ref(cnt).name]);
%     end
% end