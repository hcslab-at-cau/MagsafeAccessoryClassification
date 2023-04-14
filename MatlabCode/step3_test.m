accId = 1;
trialId = 1;

mag = data(accId).trial(trialId).mag;
gyro = data(accId).trial(trialId).gyro;

cur = result(accId, trialId);
detectRange = find(cur.filter5);
detectRange = [detectRange(1), detectRange(end)];

gyroDAngleThreshold = 0.015;
magDAngleThreshold = 0.01;


outerRange = zeros(1, 2);

tmp = movmean(mag.dAngle - gyro.dAngle, wSize);
tmp = diff(tmp);

outerRange(1) = find(tmp(1:detectRange(1) - wSize/2), 1, 'last'); 





% outerRange(1) = find(gyro.dAngle(1:detectRange(1)) > gyroDAngleThreshold, 1, 'last');
% outerRange(2) = find(gyro.dAngle(detectRange(2) - wSize / 2:end) > gyroDAngleThreshold, 1) + detectRange(2) - 1;

% 
% innerRange = zeros(1, 2);
% innerMargin = 0.05 * rate;
% 
% mu = [];
% for cnt = outerRange(1) + innerMargin:detectRange(1)    
%     mu(cnt - (outerRange(1) + innerMargin) + 1) = mean(mag.dAngle(outerRange(1):cnt));
% end
% [~, innerRange(1)] = min(mu);
% innerRange(1) = innerRange(1) + outerRange(1) + innerMargin - 1;
% 
% for cnt = detectRange(2):outerRange(2) - innerMargin
%     mu(cnt - detectRange(2) + 1) = mean(mag.dAngle(cnt:outerRange(2)));
% end
% [~, innerRange(2)] = min(mu);
% innerRange(2) = innerRange(2) + detectRange(2) - 1;


% innerRange(1) = find(mag.dAngle(outerRange(1):detectRange(1)) < magDAngleThreshold, 1, 'last') + outerRange(1) - 1;
% innerRange(2) = find(mag.dAngle(detectRange(2):outerRange(2)) < magDAngleThreshold, 1) + detectRange(2) - 1;


figure(3)
clf
subplot 511
hold on
plot(mag.dAngle)
plot(gyro.dAngle)

xline(detectRange, 'k', 'LineWidth', 1)


subplot 512
hold on
plot(mag.sample)
% xline(detectRange, 'k', 'LineWidth', 1)
xline(outerRange, 'r', 'LineWidth', 2)
% xline(innerRange, 'b', 'LineWidth', 2)

subplot 513
hold on
plot(mag.dAngle - gyro.dAngle)



subplot 514
plot(movmean(mag.dAngle - gyro.dAngle, 1 * rate))


subplot 515
corrData = zeros(1, length(mag.dAngle));
for cnt = wSize + 1:length(corrData)
    curRange = cnt - wSize + 1:cnt;
    corrData(cnt) = corr(mag.dAngle(curRange), gyro.dAngle(curRange));
end    
plot(corrData)
