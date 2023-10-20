%% Identify MagSafe accessories
params.identify.testMargin = params.data.rate * 3;

params.identify.searchRange = params.data.rate * .75;
params.identify.featureRange = params.data.rate * .1;
params.identify.prc = [10, 90];

params.identify.nTotal = length(data(1).trial);
params.identify.nTrain = params.identify.nTotal * 0.5;
params.identify.nTest = params.identify.nTotal - params.identify.nTrain;

params.identify.nRepeat = 1;

params.ref.nSub = 50;

train = ref;
test = feature;
for cnt = 1:length(length(ref))
    
    
end




refSet = [];
for cnt = 1:length(ref)
    refSet = [refSet; ref(cnt).feature];
end

tic
for cnt = 1:length(result)
% for cnt = 6
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
        cur.tTest = feature(cnt).trial(cnt2).detect.sample;
        cur.tTest = reshape(cur.tTest, 2, length(cur.tTest)/2)';
        cur.details = double(result(cnt).trial(cnt2).detect.all);        
        cur.bias = zeros(size(cur.details, 1), 3);

        mag = feature(cnt).trial(cnt2).rmag;      

        gyro = feature(cnt).trial(cnt2).gyro;        
        % Perform individual tests for each attach-detach pair
        for cnt3 = 1:size(cur.tTest, 1)
            range = max(1, cur.tTest(cnt3, 1) - params.identify.testMargin): ...
                min(length(cur.details), cur.tTest(cnt3, 2) + params.identify.testMargin);
            idx = find(cur.details(range)) + range(1) - 1;
                        
            % Intially nothing attached
            attached.id = length(ref) + 1;
            attached.bias = [0, 0, 0];
            for cnt4 = idx'        
                diff = func_compute_bias(mag, gyro, attached.bias, cnt4, ...
                    params.identify.searchRange, params.identify.featureRange, params.identify.prc);                               

                err = sqrt(sum((refSet - diff).^2, 2));
                err(end + 1) = sqrt(sum(diff.^2));
 
                [~, identified] = sort(err);
                identified = ceil(identified / params.ref.nSub);
 
                if identified(1) == length(ref) + 1
                    if attached.id == length(ref) + 1
                        cur.details(cnt4) = -1;
                    else
                        cur.details(cnt4) = identified(1);                                                
                        cur.bias(cnt4, :) = diff; 
                        
                        attached.id = identified(1);
                        attached.bias = diff;
                    end
                else
                    identified(identified == length(ref) + 1) = [];                
                    identified([ref(identified).isChargeable] ~= result(cnt).isChargeable) = [];
                    identified = identified(1);

                    if attached.id == length(ref) + 1
                        cur.details(cnt4) = identified;
                        cur.bias(cnt4, :) = diff;
                        
                        attached.id = identified;
                        attached.bias = diff;
                    else
                        cur.details(cnt4) = -1;
                    end
                end

%                 disp(diff)
%                 disp('=========')
            end
        end
        result(cnt).trial(cnt2).identify = cur;
    end
end
toc

%% Plotting detection results
% figure(1)
% clf
% nRow = length(result);
% nCol = length(result(1).trial);
% for cnt = 1:length(result)
%     for cnt2 = 1:length(result(cnt).trial)
%         cur = result(cnt).trial(cnt2).identify;
%         subplot(nRow, nCol, (cnt - 1) * nCol + cnt2)
%         hold on
%         plot(cur.details)
%         plot(ones(1, length(cur.details)) * result(cnt).class)
%         plot(ones(1, length(cur.details)) * length(ref) + 1)
%         title(result(cnt).name)
%     end
% end