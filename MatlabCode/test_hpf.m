rate = 100;
order = 4;
[b.hp, a.hp] = butter(order, 10/rate * 2, 'high');
Wn = [5 15]/rate *2;
[b.bp, a.bp] = butter(order, Wn, 'bandpass');

accId = 4;
trialId = 1;
disp(data(accId).name)

mag = data(accId).trial(trialId).mag.sample;
% range = 1:length(mag);
range = 580:630;


bpMagnitude = sum(filtfilt(b.bp, a.bp, mag(range, :)).^2, 2);
hpMagnitude = sum(filtfilt(b.hp, a.hp, mag(range, :)).^2, 2);

figure(24)
clf

subplot(1, 2, 1)
plot(bpMagnitude)
title('bandpass')

subplot(1, 2, 2)
plot(hpMagnitude)
title('highpass')