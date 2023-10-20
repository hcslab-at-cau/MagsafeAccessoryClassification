function [] = func_plot_detected(data, result, mType, dId, tId)
mag = data(dId).trial(tId).(mType);
gyro = data(dId).trial(tId).gyro;
result = result(dId).trial(tId).detect;

clf
subplot 611
plot(mag.magnitude)

subplot 612
plot(mag.diff)

subplot 613
plot(sum(gyro.raw.^2, 2))

subplot 614
plot(result.mag)

subplot 615
plot(result.diff)

subplot 616
plot(result.all)
end