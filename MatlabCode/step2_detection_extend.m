prevRanges = (-100:-1);
nextRanges = (1:50);
extractRanges = (-100:50);

features = struct();

for cnt = 1:length(data)
    for cnt2 = 1:nTrials
        detect = detected(cnt).trial(cnt2).filter7;
        mag = data(cnt).trial.mag;
        gyro = data(cnt).trial.gyro;

        cur = struct();
        
        for cnt3 = find(detect)'
            prev = cnt3 + prevRanges;
            next = cnt3 + nextRanges;

            cur.mag = mag.sample(extractRanges, :);
            cur.gyro = gyro.sample(extractRanges, :);
            
            


        end
        features(cnt).trial(cnt2) = cur;
    end

end