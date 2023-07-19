accId = 4;
trialId = 8;
points = 10;
attachRange = ((-wSize - points):(fix(wSize/2)));
calRange = 1 + wSize + (-wSize:fix(wSize/2));

tmp = data(accId).trial(trialId);
groundTruth = tmp.detect.sample;
mag = tmp.mag;
gyro = tmp.gyro.sample;

figure(25)
clf

nRow = 1;
nCol = 1;

subplot(nRow, nCol, 1)
hold on
plot(mag.diffSum)

for cnt2 = 1:2:length(groundTruth)
    pnt = groundTruth(cnt2);
    range = pnt + attachRange;
    stem(range, mag.diffSum(range), 'LineStyle', 'none')
    
    if range(1) < 2
        range = 2:range(end);
    end

    if range(end) > length(gyro)
        range = range(1):length(gyro);
    end

    featureValue = zeros(1, 3);
    for cnt3 = 1:points
        t = range(1) + cnt3;
        subRange = t + calRange;

        [f, iv] = func_extract_feature(mag.sample, gyro, subRange, 1, rate);
    %    disp(f)
        featureValue = f+featureValue;
    end
    featureValue = featureValue / points;
    disp(featureValue)
end