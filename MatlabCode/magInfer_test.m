tmp = data(4).trial(1);
mag = tmp.mag;
gyro = tmp.gyro.sample;

range = 763:1055;

refMag = mag.sample(762, :);
for t = range
    euler = gyro(t, :) * 1/rate;gigy5sggggggggss
    rotm = eul2rotm(euler, 'XYZ');
    inferMag = (rotm\refMag')';

    refMag = inferMag;
end

disp(inferMag)
disp(mag.sample(1056, :))