accId = 5;
trialId = 2;

tmp = data(accId).trial(trialId);
data(accId).name
mag = tmp.mag;
acc = tmp.acc;
gyro = tmp.gyro;
click = tmp.detect.sample(1);
rate = 100;

start = click-201;

point = mag.sample(start, :);

inferredMag = zeros(length(mag.sample), 3);
refMag = point;

for t= click-200:click
    euler = gyro.sample(t, :) * 1/rate;
    rotm = eul2rotm(euler, 'XYZ');

    inferredMag(t, :) = (rotm\(refMag)')';
    refMag = inferredMag(t, :);
end

features = [];

for t = click + 1:length(mag.diff)
    euler = gyro.sample(t, :) * 1/rate;
    rotm = eul2rotm(euler, 'XYZ');

    inferredMag(t, :) = (rotm\(refMag)')';
    refMag = inferredMag(t, :);

    tmp = mag.sample(t, :) - refMag;
    features(end + 1, :) = tmp;
end
%%
magnitude = features;
filtered = [];
lst = [];
varLst = [];

interval = 10;

for cnt = interval + 1:length(magnitude)
    range = cnt + (-interval:-1);
    v = var(magnitude(range, :));

    varLst(end + 1) = rssq(v);
end

for cnt = interval + 1:length(magnitude)-interval
    range = cnt + (-interval:interval);
    v = var(magnitude(range, :));
    % lst(end + 1) = rssq(v);

    if rssq(v) < 1.0
        lst(end + 1) = rssq(v);
    end
end

threshold = mean(lst)*2

for cnt = interval + 1:length(magnitude)-interval
    range = cnt + (-interval:interval);
    v = var(magnitude(range, :));

    if rssq(v) > threshold
        filtered(end + 1, :) = features(cnt, :);
    end
end
%%
num = 100;

fig = figure(num);
clf
fig.Position(1:2) = [200, 800];
clf
hold on

ranges = 1:length(features);
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


fig = figure(num + 2);
clf
fig.Position(1:2) = [800, 800];
clf
hold on

ranges = 1:length(filtered);
cnt = 4;
interval = fix(length(filtered)/cnt);

labels = 1:cnt;

for cnt2 = 1:cnt
    randomColor = rand(1, 3);
    range = 1 + interval*(cnt2-1):interval*cnt2;
    p = filtered(range, :);
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

fig = figure(num+3);
clf
fig.Position(1:2) = [1400, 800];
hold on
plot(mag.diff)
stems = [click-200,click+100:length(mag.diff)];
stem(stems, mag.diff(stems), 'LineStyle','none')
legend({'x', 'y', 'z', 'stems'})

disp(['Original => ', num2str(length(features)) ' result : ', num2str(length(filtered))])