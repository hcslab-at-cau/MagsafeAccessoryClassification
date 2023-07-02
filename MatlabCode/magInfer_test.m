tmp = data(4).trial(1);
mag = tmp.mag;
gyro = tmp.gyro;

beginIdx = 700;
lastIdx = 1000;
range = beginIdx:lastIdx;

inferMag = zeros(length(range), 3);
refMag = mag.sample(beginIdx-1, :);
for t = 1:length(range)
    euler = gyro.sample(range(t), :) * 1/rate;
    rotm = eul2rotm(euler, 'XYZ');
    inferMag(t, :) = (rotm\refMag')';

    refMag = inferMag(t, :);
end

euler = sum(gyro.sample(range, :)) * 1/rate;
rotm = eul2rotm(euler, 'XYZ');
inferMag2 = (rotm\mag.sample(beginIdx-1, :)')';


figure(9)
clf

nCol = 1;
nRow = 5;

subplot(nRow, nCol, 1)
plot(mag.sample(range, :))
title('mag sample')

subplot(nRow, nCol, 2)
plot(mag.inferMag(range, :))
title('inferMag')

subplot(nRow, nCol, 3)
plot(mag.diff(range, :))
title('diff')

subplot(nRow, nCol, 4)
plot(inferMag)
title('ref = begin -1')

subplot(nRow, nCol, 5)
plot(mag.inferAngle(range))
title('inferAngle')
