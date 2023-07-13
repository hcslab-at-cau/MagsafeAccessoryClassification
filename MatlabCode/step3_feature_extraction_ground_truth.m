% In this feature plot, Using Ground-truth

for cnt = 1:length(data)
    nTrials = length(data(cnt).trial);
    
    for cnt2 = 1:nTrials
        tmp = data(cnt).trial(cnt2);
        
        mag = tmp.mag;
        groundTruth = tmp.detect.sample;
        gyro = tmp.gyro;

        for t = groundTruth
            
        end
        

    end

end