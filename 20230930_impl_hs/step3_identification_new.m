%% Identify MagSafe accessories
params.identify.featureSource = params.data.rate * 3;
params.identify.featureRange = params.data.rate * .5 + (1:params.data.rate * 2);
params.identify.testMargin = params.data.rate * 3;

refSet = [];
for cnt = 1:length(ref)
    refSet = [refSet; ref(cnt).feature];
end


tic
for cnt = 1:length(result)
% for cnt = 2
    class = find(cellfun('isempty', strfind({ref.name}, data(cnt).name)) == 0);
    if isempty(class)
        class = 0;
    end
    result(cnt).name = data(cnt).name;
    result(cnt).class = class;
    result(cnt).isChargeable = func_isChargeable(result(cnt).name);

    for cnt2 = 1:length(result(cnt).trial)
%     for cnt2 = 2
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
            attachedBias = [0, 0, 0];
            for cnt4 = idx'                                
                % Find the accessory that minimizes diff errors.
                range = cnt4 + params.identify.featureRange;
                range(range > length(feature(cnt).trial(cnt2).identify)) = [];
                                
                src = feature(cnt).trial(cnt2).detect.rmag.calibrated(cnt4 - params.identify.featureSource, :);
                q = feature(cnt).trial(cnt2).detect.gyro.cumQ(cnt4 - params.identify.featureSource, :);                

                dst = feature(cnt).trial(cnt2).detect.rmag.calibrated(range, :);
                cumQ = feature(cnt).trial(cnt2).detect.gyro.cumQ(range, :);
                
                if attached ~= length(ref) + 1                    
                    src = src - attachedBias;
                    dst = dst + attachedBias;
                end
                
                src = quatrotate(quatinv(q), src);                                       
                inferred = quatrotate(cumQ, src);
                
                diff = mean(dst - inferred);
                err = sqrt(sum((refSet - diff).^2, 2));                
                err(end + 1) = sqrt(sum(mean(dst - 2 * attachedBias - inferred).^2));
%                 err(end + 1) = sqrt(sum(diff.^2));

                [~, identified] = sort(err, 'ascend');                
                identified = ceil(identified / params.ref.nSub);  
                
                
                if identified(1) == length(ref) + 1
                    cur.details(cnt4) = -1;
                else
                    identified(identified == length(ref) + 1) = [];                
                    identified([ref(identified).isChargeable] ~= result(cnt).isChargeable) = [];                    
                    identified = identified(1);                                        
                                    
                    if attached == length(ref) + 1 && identified ~= length(ref) + 1
                        cur.details(cnt4) = identified;
                        attached = identified;
                        attachedBias = diff;
                    elseif attached ~= length(ref) + 1 && attached == identified
                        cur.details(cnt4) = length(ref) + 1;
                        attached = length(ref) + 1;
                        attachedBias = [0, 0, 0];
                    else
                        cur.details(cnt4) = -1;
                    end
                end
                
                    
                
%                 if identified == attached 
%                     % False positive if an accessory is not newly attached or detached
%                     cur.details(cnt4) = -1;
%                 elseif attached ~= length(ref) + 1 && identified ~= length(ref) + 1
%                     % False positive if an attach event is detected without detaching the existing one
%                     cur.details(cnt4) = -1;
%                 else
%                     % Attach or detach events! 
%                     cur.details(cnt4) = identified;
%                     attached = identified;
%                     
%                     if attached ~= length(ref) + 1
%                         attachedBias = diff;
%                     end
%                 end
            end
        end
        result(cnt).trial(cnt2).identify = cur;
    end
end
toc

%% Plotting detection results
figure(1)
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