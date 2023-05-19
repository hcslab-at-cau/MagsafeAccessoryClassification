% Detach는 attach가 안 일어나면 일어나지 않은 event 라 생각.

for cnt = 1:length(data)
    for cnt2 = 1:nTrials
        state = false;
        detect = detected(cnt).trial(cnt2).filter6;

        for cnt3 = find(detect)'
            if state == false
                state = true;

                
            else
                state = false;
            end


        end
        
    end

end