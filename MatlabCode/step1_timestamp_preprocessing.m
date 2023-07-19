timeThreshold = 5;
warning('off','all')
warning

for cnt = 1:length(data)
    nTrials = length(data(cnt).trial);

    for cnt2 = 1:nTrials
        cur = data(cnt).trial(cnt2);
        motionLength = min([length(cur.mag.sample), length(cur.acc.sample), length(cur.gyro.sample)]);
        rmagLength = length(cur.rmag.sample);

        motionTime = cur.time.sample;
        rmagTime= cur.timeRaw.sample;
        q = (rmagTime(1) - motionTime(1))/10;
        initIndex = fix(q) + mod(q, 5) + 1;
        
        % Arrange first timestamp to start at almostly equal time(with in 5ms).
        if initIndex > 0
            cur.mag.sample = cur.mag.sample(initIndex:motionLength, :);
            cur.gyro.sample = cur.gyro.sample(initIndex:motionLength, :);
            cur.acc.sample = cur.acc.sample(initIndex:motionLength, :);
            cur.time.sample = cur.time.sample(initIndex:motionLength);
        elseif initIndex < 0
            cur.rmag.sample = cur.acc.sample(-initIndex:rmagLength, :);
            cur.timeRaw.sample = cur.timeRaw.sample(-initIndex:rmagLength);
        end

        % Arrange total timestamp to match with in 5ms
        motionLength = length(cur.mag.sample);
        motionTime = cur.time.sample;

        rmagLength = length(cur.rmag.sample);
        rmagTime= cur.timeRaw.sample;

        lResult = min([motionLength, rmagLength]);

        for t = 1:lResult
            interval = cur.time.sample(t) - cur.timeRaw.sample(t);

            if abs(interval) > timeThreshold
                if cur.time.sample(t) > cur.timeRaw.sample(t)
                    cur.rmag.sample(t, :) = [];
                    cur.timeRaw.sample(t) = [];
                    % detect 
                else
                    cur.mag.sample(t, :) = [];
                    cur.acc.sample(t, :) = [];
                    cur.gyro.sample(t, :) = [];
                    cur.time.sample(t) = [];
                end
            end

            if t >= min([length(cur.mag.sample), length(cur.rmag.sample)])
                break
            end
        end

        if length(cur.mag.sample) ~= length(cur.rmag.sample)
            minLength = min([length(cur.mag.sample), length(cur.rmag.sample)]);
            cur.acc.sample = cur.acc.sample(1:minLength, :);
            cur.mag.sample = cur.mag.sample(1:minLength, :);
            cur.gyro.sample = cur.gyro.sample(1:minLength, :);
            cur.time.sample = cur.time.sample(1:minLength);

            cur.rmag.sample = cur.rmag.sample(1:minLength, :);
            cur.timeRaw.sample = cur.timeRaw.sample(1:minLength);
        end

        data(cnt).trial(cnt2) = cur;
    end

end