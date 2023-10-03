function [] = func_plot_detected(data, detected, dId, tId)
cur = detected(dId).trial(tId);

clf
subplot 511
plot(data(dId).trial(tId).rmag.magnitude)

subplot 512
plot(data(dId).trial(tId).rmag.diff)

subplot 513
plot(cur.mag)

subplot 514
plot(cur.diff)

subplot 515
plot(cur.all)
end