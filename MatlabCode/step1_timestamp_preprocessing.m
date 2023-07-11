

for cnt = 1:length(data)
    nTrials = length(data(cnt).trial);

    for cnt2 = 1:nTrials
        motionTime = data(cnt).trial(cnt2).timestamp_calibrated;
        rmagTime= data(cnt).trial(cnt2).timestamp_raw;
        
    end

end