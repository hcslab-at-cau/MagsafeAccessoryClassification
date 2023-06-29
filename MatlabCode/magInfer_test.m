tmp = data(4).trial(1);
mag = tmp.mag;
gyro = tmp.gyro;

beginIdx = 700;
lastIdx = 1000;
range = beginIdx:lastIdx;

refMag = mag.sample(beginIdx-1, :);
for t = range
    euler = gyro.sample(t, :) * 1/rate;
    rotm = eul2rotm(euler, 'XYZ');
    inferMag = (rotm\refMag')';

    refMag = inferMag;
end

euler = sum(gyro.sample(range, :)) * 1/rate;
rotm = eul2rotm(euler, 'XYZ');
inferMag2 = (rotm\mag.sample(beginIdx-1, :)')';


disp(inferMag)
disp(inferMag2)
disp(mag.sample(lastIdx, :))