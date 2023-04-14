accId = 6;
trialId = 1;

mag = data(accId).trial(trialId).mag;
gyro = data(accId).trial(trialId).gyro;

cur = result(accId, trialId);
detectRange = find(cur.filter5);
detectRange = [detectRange(1), detectRange(end)];

gyroDAngleThreshold = 0.015;
magDAngleThreshold = 0.01;


outerRange = zeros(1, 2);
outerRange(1) = find(gyro.dAngle(1:detectRange(1)) > gyroDAngleThreshold, 1, 'last');
outerRange(2) = find(gyro.dAngle(detectRange(2):end) > gyroDAngleThreshold, 1) + detectRange(2) - 1;


innerRange = zeros(1, 2);
innerRange(1) = find(mag.dAngle(1:detectRange(1)) < magDAngleThreshold, 1, 'last');
innerRange(2) = find(mag.dAngle(detectRange(2):end) < magDAngleThreshold, 1) + detectRange(2) - 1;


figure(3)
clf
subplot 211
hold on
plot(mag.dAngle)
plot(gyro.dAngle)

xline(detectRange, 'k', 'LineWidth', 1)
xline(outerRange, 'r', 'LineWidth', 2)
xline(innerRange, 'b', 'LineWidth', 2)


subplot 212
hold on
plot(mag.sample)

% xline(detectRange, 'k', 'LineWidth', 1)
xline(outerRange, 'r', 'LineWidth', 2)
xline(innerRange, 'b', 'LineWidth', 2)