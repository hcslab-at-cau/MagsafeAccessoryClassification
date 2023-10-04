accId = 5;
showTrials = 1:2;

cur = data(accId).trial(1);
mag = cur.mag;
fs = 100;
attachInterval = (wSize:4*wSize);

[b.mag, a.mag] = butter(4, 5/100 * 2, 'high');

for cnt = 1:length(showTrials)
    idx = showTrials(cnt);

    cur = data(accId).trial(idx);
    acc = cur.acc;
    mag = cur.mag;
    gyro = cur.gyro;
    click = cur.detect.sample;

    figure(idx + accId * 10)
    clf

    iter = 1:2:length(click);
    
    nRow = 2;
    nCol = length(iter);

    for cnt2 = iter
        t = click(cnt2);
        range = t + attachInterval;

        if range(1) < 2
            range = 2:range(end);
        end

        if range(end) > length(mag.sample)
            range = range(1):length(mag.sample);
        end

        gyroAngles = zeros(length(range), 1);
        angle = 0;
        for cnt3 = 1:length(range)
            k = range(cnt3);

            variance = sum(gyro.sample(k ,: ), "all") * 1/rate; 

            gyroAngles(cnt3) = angle + variance;
            angle = angle + variance;
        end

        magAngles= zeros(length(range), 1);
        angle = 0;

        for cnt3 = 2:length(range)
            k = range(cnt3);
            prev = mag.sample(k-1, :);
            cur = mag.sample(k, :);
     
            v = acos(dot(prev, cur)/(norm(prev)*norm(cur)));
            
            c = cross(prev, cur);

            if c(3) > 0
                v = -v;
            end

            magAngles(cnt3) = angle + v;
            angle = angle + v;
        end
        
        i = find(iter==cnt2);

        samples = filtfilt(b.mag, a.mag, mag.diff(range, :));

        subplot(nRow, nCol, i)
        plot(gyroAngles)
        title('gyro Angle')
        
        subplot(nRow, nCol, nCol + i)
        plot(magAngles)
        title('mag Angle')
    end
end

%% 

accId = 7;
trialId = 1;

[b.gyro, a.gyro] = butter(4, 1/rate * 2, 'high');
[b.acc, a.acc] = butter(4, 1/rate * 2, 'high');


detect = detected(accId).trial(trialId).filter5;

cur = data(accId).trial(trialId);
acc = cur.acc;
gyro = cur.gyro;
click = cur.detect.sample;

angles = zeros(length(gyro.sample), 1);
varArray = zeros(length(gyro.sample), 1);

angle= 0;

for cnt = 1:length(gyro.sample)
    variance = sum(gyro.sample(cnt, :), 2) * 1/rate; 
    
    angle= angle + variance;
    angles(cnt) = angle;

    if cnt > 100
        range = cnt + (-100:-1);
        fh = filtfilt(b.gyro, a.gyro, angles(range));
        varArray(cnt) = mean(abs(fh));
    end     
end


figure(4)
clf

nRow = 3;
nCol = 1;

gyroHPF = sum(filtfilt(b.gyro, a.gyro, gyro.sample), 2);


subplot(nRow, nCol, 1)
hold on
plot(gyroHPF)
stem(click, gyroHPF(click), 'filled')
title('gyro hpf')

accHPF = sum(filtfilt(b.acc, a.acc, acc.sample).^2, 2);

subplot(nRow, nCol, 2)
hold on
plot(accHPF)
stem(click, accHPF(click), 'filled')
title('acc hpf')

filter1 = abs(gyroHPF) > 5 & abs(accHPF) > 1;

detect = find(detect);

subplot(nRow, nCol, 3)
hold on
plot(filter1)
stem(click, filter1(click), 'filled')
% stem(detect, filter1(detect), 'filled')
title('gyro & acc')