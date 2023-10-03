function [] = func_plot_detected(data, result, dId, tId)
data = data(dId).trial(tId).detect.rmag;
result = result(dId).trial(tId).detect;

clf
subplot 511
plot(data.magnitude)

subplot 512
plot(data.diff)

subplot 513
plot(result.mag)

subplot 514
plot(result.diff)

subplot 515
plot(result.all)
end