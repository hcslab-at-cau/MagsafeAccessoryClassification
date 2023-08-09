accId = 1;
trialId = 1;

tmp = data(accId).trial(trialId);
mag = tmp.mag;
acc = tmp.acc;
gyro = tmp.gyro;
click = tmp.detect.sample(1);
rate = 100;

start = click-201;

point = mag.sample(start, :);

inferredMag = zeros(length(mag.sample), 3);
refMag = point;

for t= click-200:click+99
    euler = gyro.sample(t, :) * 1/rate;
    rotm = eul2rotm(euler, 'XYZ');

    inferredMag(t, :) = (rotm\(refMag)')';
    refMag = inferredMag(t, :);
end

features = [];

for t = click+ 100:length(mag.diff)
    euler = gyro.sample(t, :) * 1/rate;
    rotm = eul2rotm(euler, 'XYZ');

    inferredMag(t, :) = (rotm\(refMag)')';
    refMag = inferredMag(t, :);

    tmp = mag.sample(t, :) - refMag;
    features = [features;tmp];
end


figure(123)
clf
hold on

ranges = click + 100:length(mag.diff);
cnt = 4;
interval = fix(length(ranges)/cnt);

labels = 1:cnt;

for cnt2 = 1:cnt
    randomColor = rand(1, 3);
    range = 1 + interval*(cnt2-1):interval*cnt2;
    p = features(range, :);
    scatter3(p(:,1), p(:,2), p(:,3), 'filled', 'MarkerFaceColor', randomColor, 'MarkerEdgeColor', randomColor);
end

legend({'1', '2', '3', '4'})
xlabel('x')
ylabel('y')
zlabel('z')

% p = features(range1, :);
% scatter3(p(:,1), p(:,2), p(:,3), 'filled');
% hold on
% 
% p = features(range2, :);
% scatter3(p(:,1), p(:,2), p(:,3));

figure(124)
clf
hold on
plot(mag.diff)
stems = [click-200,click+100:length(mag.diff)];
stem(stems, mag.diff(stems), 'LineStyle','none')
