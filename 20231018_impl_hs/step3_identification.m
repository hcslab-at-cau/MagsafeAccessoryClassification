%% Identify MagSafe accessories
params.identify.featureSource = params.data.rate * .5;
params.identify.featureRange = params.data.rate * .5 + (1:params.data.rate * 2);
params.identify.testMargin = params.data.rate * 3;

params.identify.threshold = .5;


refSet = [];
for cnt = 1:length(ref)
    refSet = [refSet; ref(cnt).feature];
end

tic
for cnt = 1:length(result)
% for cnt = 4
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

        mag = feature(cnt).trial(cnt2).rmag;      
        mag.safePts = find(mag.mean <= params.identify.threshold);

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
                for cnt5 = 2:length(mag.safePts)
                    if mag.safePts(cnt5 - 1) < cnt4 && mag.safePts(cnt5) > cnt4
                        src.pts = mag.safePts(cnt5 - 1);
                        dst.pts = mag.safePts(cnt5);
                        break;
                    end
                end

                src.mag = mag.calibrated(src.pts, :) - attached.bias;
                src.q = gyro.cumQ(src.pts, :);

                dst.mag = mag.calibrated(dst.pts, :);
                dst.q = gyro.cumQ(dst.pts, :);

                src.rotated = quatrotate(quatinv(src.q), src.mag);
                src.rotated = quatrotate(dst.q, src.rotated);

                diff = dst.mag - src.rotated;
                err = sqrt(sum((refSet - diff).^2, 2));
                err(end + 1) = sqrt(sum(diff.^2));

                [~, identified] = sort(err);
                identified = ceil(identified / params.ref.nSub);

                if identified(1) == length(ref) + 1
                    if attached.id == length(ref) + 1
                        cur.details(cnt4) = -1;
                    else
                        cur.details(cnt4) = identified(1);
                    end

                    attached.id = identified(1);
                    attached.bias = [0, 0, 0];
                else
                    identified(identified == length(ref) + 1) = [];                
                    identified([ref(identified).isChargeable] ~= result(cnt).isChargeable) = [];
                    identified = identified(1);

                    if attached.id == length(ref) + 1
                        cur.details(cnt4) = identified;
                        attached.id = identified;
                        attached.bias = mean(ref(attached.id).feature);
                    else
                        cur.details(cnt4) = -1;
                    end
                end

%                 disp(identified(1))
%                 disp('=========')
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