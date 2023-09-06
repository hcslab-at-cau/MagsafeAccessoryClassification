accId = 4;
showTrials = 1:1;

cur = data(accId).trial(1);
mag = cur.mag;
fs = 100;
attachInterval = (-400:-100);

[b.mag, a.mag] = butter(4, 5/100 * 2, 'high');

for cnt = 1:length(showTrials)
    idx = showTrials(cnt);

    cur = data(accId).trial(idx);
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
