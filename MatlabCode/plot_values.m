figure(8)
clf

accId = 11;
showTrials = 1:2;

nCol = length(showTrials);
nRow = 3;
disp(data(accId).name)

for cnt = 1:length(showTrials)
    detect = detected(accId).trial(showTrials(cnt)).filter6;
    mag = data(accId).trial(showTrials(cnt)).rmag;
    gyro = data(accId).trial(showTrials(cnt)).gyro;

    diff = zeros(length(mag.sample), 3);
    [calm, bias, ~] = magcal(mag.rawSample(1:500, :));
    mag.sample = (mag.rawSample-bias)*calm;

    refMag = mag.sample(1, :);
    for t = 2:length(mag.sample)
        euler = gyro.sample(t, :) * 1/100;
        rotm = eul2rotm(euler, 'XYZ');
        refMag = (rotm\(refMag)')';

        diff(t, :) = mag.sample(t, :) - refMag;
    end

    subplot(nRow, nCol, cnt)
    hold on
    plot(diff)
    title('diff')
    legend({'x', 'y', 'z'})

    subplot(nRow, nCol, nCol + cnt)
    plot(mag.sample)
    title('mag values')

    subplot(nRow, nCol, nCol*2 + cnt)
    plot(mag.inferAngle)
end

%%

tmp = data(accId).trial(3);
mag = tmp.mag;
gyro = tmp.gyro;
detect = tmp.detect.sample;

t = detect(1);
ranges = t + (-200:50);
sample = mag.sample(ranges, :);

refMag = mag.sample(ranges(1), :);
diff = zeros(length(ranges), 3);
inferredMag = zeros(length(ranges), 3);
inferredMag(1, :) = refMag;

for cnt = 2:length(ranges)
    euler = gyro.sample(ranges(cnt), :) * 1/100;
    rotm = eul2rotm(euler, 'XYZ');

    inferredMag(cnt, :) =(rotm\refMag')';
    refMag= inferredMag(cnt, :);
    diff(cnt, :) = sample(cnt, :) - inferredMag(cnt, :);
end

figure(42)
clf

subplot(3, 1, 1)
plot(sample)

subplot(3, 1, 2)
plot(inferredMag)

subplot(3, 1, 3)
plot(diff)