accId = 11;
trialId = 1;

rate = 100;
order = 4;
[b.mag, a.mag] = butter(order, 5/rate * 2, 'high');
Wn = [5 15]/rate *2;
[b.acc, a.acc] = butter(order, 30/rate * 2, 'high');

disp(data(accId).name)

mag = data(accId).trial(trialId).mag.sample;
acc=  data(accId).trial(trialId).acc.sample;
% range = 1:length(mag);
range = 2800:3200;


maghp = sum(filtfilt(b.mag, a.mag, mag).^2, 2);
acchp = sum(filtfilt(b.acc, a.acc, acc).^2, 2);

figure(24)
clf

subplot(1, 2, 1)
plot(acchp)
title('acc highpass')


subplot(1, 2, 2)
plot(maghp)
title('mag highpass')
