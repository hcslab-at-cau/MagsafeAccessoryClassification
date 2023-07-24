 %% For unit feature extraction point to point
rotOrder = 'XYZ';
attachInterval = (-wSize*2:wSize/2);
% attachCalibration = (-wSize*3:-wSize);
detachInterval = (-wSize:wSize*2);
featureUnit = struct();

if newApp == false
    groundTruthData = func_load_ground_truth(datasetName, folderName);
end

tic
for cnt = 1:length(data)
    featureUnit(cnt).name = data(cnt).name;
    nTrials = length(data(cnt).trial);

    for cnt2 = 1:nTrials
        curUnit = struct();
        curRange = struct();
        tmp = data(cnt).trial(cnt2);
        mag = tmp.mag.sample;
        gyro = tmp.gyro.sample;
        
        if newApp == false
            groundTruth = rmmissing(groundTruthData.([featureUnit(cnt).name, '_', num2str(cnt2)]));
        else
            groundTruth = tmp.detect.sample;
        end
    
        k = 1;

        if length(groundTruth) ~= 10
            disp(cnt2)
        end
        
        for cnt3 = 1:length(groundTruth)
            if mod(cnt3, 2) == 1
                range = groundTruth(cnt3) + attachInterval;
            else
                range = groundTruth(cnt3) + detachInterval;
            end
            

            [featureValue, inferredMag] = func_extract_feature(mag, gyro, range, 1, rate);
            
            if mod(cnt3, 2) == 1
                curUnit(k).attach = featureValue; % for attach
            else
                curUnit(k).detach = featureValue; % for detach
                k = k + 1;
                
            end
        end

        featureUnit(cnt).trial(cnt2).cur = curUnit;
    end
end
toc
%% For range feature extraction point to point
points = 10;
% attachRange = ((-wSize*2 - points):(fix(wSize/2) + points));
% calRange = 1 + wSize*2 + (-wSize*2:fix(wSize/2) + points);
attachRange = ((-wSize*2 - points):(fix(wSize/2) + points));
% calRange = 1 + wSize*2 + (-wSize*2:fix(wSize/2) + points);
calRange = 1:(wSize*2 + fix(wSize/2) + points);
featureRange = struct();

tic
for cnt = 1:length(data)
    featureRange(cnt).name = data(cnt).name;
    nTrials = length(data(cnt).trial);

    for cnt2 = 1:nTrials
        curRange = struct();
        tmp = data(cnt).trial(cnt2);
        mag = tmp.mag;
        gyro = tmp.gyro.sample;

        if newApp == false
            groundTruth = rmmissing(groundTruthData.([featureUnit(cnt).name, '_', num2str(cnt2)]));
        else
            groundTruth = tmp.detect.sample;
        end

        k = 1;

        if length(groundTruth) ~= 10
            disp(cnt2)
        end
        
        for cnt3 = 1:length(groundTruth)
            range = groundTruth(cnt3) + attachRange;           
            featureTmp = zeros(1, 3);

            for cnt4 = 1:points
                t = range(1) + cnt4;
                subRange = t + calRange;
        
                [f, iv] = func_extract_feature(mag.sample, gyro, subRange, 1, rate);
                featureTmp = f+featureTmp;
            end
            
            if mod(cnt3, 2) == 1
                curRange(k).attach = featureTmp / points;
            else
                curRange(k).detach = featureTmp / points;
                k = k + 1;
            end
        end

        featureRange(cnt).trial(cnt2).cur = curRange;
    end
end
toc
%% For range feature extraction range to range

points = 10;
attachRange = ((-wSize*2 - points):(fix(wSize/2) + points));
calRange = 1:(wSize*2 + fix(wSize/2) + points);
featureRangeRange = struct();

tic
for cnt = 1:length(data)
    featureRangeRange(cnt).name = data(cnt).name;
    nTrials = length(data(cnt).trial);

    for cnt2 = 1:nTrials
        curRange = struct();
        tmp = data(cnt).trial(cnt2);
        mag = tmp.mag;
        gyro = tmp.gyro.sample;
        if newApp == false
            groundTruth = rmmissing(groundTruthData.([featureUnit(cnt).name, '_', num2str(cnt2)]));
        else
            groundTruth = tmp.detect.sample;
        end
        k = 1;

        if length(groundTruth) ~= 10
            disp(cnt2)
        end
        
        for cnt3 = 1:length(groundTruth)
            range = groundTruth(cnt3) + attachRange;           
            featureTmp = zeros(1, 3);

            for cnt4 = 1:points
                t1 = range(1) + cnt4;
                for cnt5 = 1:points
                    
                    subRange = t1:(range(end)-cnt5);
                    [f, iv] = func_extract_feature(mag.sample, gyro, subRange, 1, rate);
                    featureTmp = f+featureTmp;
                end      
            end
            
            if mod(cnt3, 2) == 1
                curRange(k).attach = featureTmp / (points*points);
            else
                curRange(k).detach = featureTmp / (points*points);
                k = k + 1;
            end
        end

        featureRangeRange(cnt).trial(cnt2).cur = curRange;
    end
end
toc
%% plot features
featureFigNum = 40;
usingGroundTruth = true;
% 
% feature = featureUnit;
% run('plot_feature.m')
% 
% featureFigNum = featureFigNum + 1;

% feature = featureRange;
% run('plot_feature.m')
% 
% featureFigNum = featureFigNum + 1;

feature = featureRangeRange;
run('plot_feature.m')