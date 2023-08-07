accId = 1;
trialId = 1;

tmp = data(accId).trial(trialId);
mag = tmp.mag;
acc = tmp.acc;
click = tmp.detect;

point = mag.diff(click);



figure(123)
clf

plot(mag.diff)