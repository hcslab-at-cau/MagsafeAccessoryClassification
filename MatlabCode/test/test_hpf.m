accId = 1;
trialId = 4;

rate = 100;
order = 4;
[b.mag, a.mag] = butter(order, 5/rate * 2, 'high');
Wn = [5 15]/rate *2;
[b.acc, a.acc] = butter(order, 5/rate * 2, 'low');

disp(data(accId).name)

mag = data(accId).trial(trialId).mag.sample;
acc=  data(accId).trial(trialId).acc.sample;
detect = data(accId).trial(trialId).detect.sample;
% range = 1:length(mag);
range = 2800:3200;


maghp = sum(filtfilt(b.mag, a.mag, mag).^2, 2);
acchp = sum(filtfilt(b.acc, a.acc, acc).^2, 2);

figure(25)
clf

subplot(1, 2, 1)
hold on
plot(acchp)
title('acc lowpass')
stem(detect, acchp(detect), 'filled')

subplot(1, 2, 2)
plot(maghp)
title('mag highpass')
