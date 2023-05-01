accId = 6;
trials = 22:25;

nCol = length(trials);
nRow = 5;

figure(nCol*nRow)
clf

cnt = 1;
for trialId = trials
    objectName = data(accId).name;
    mag = data(accId).trial(trialId).mag;
    gyro = data(accId).trial(trialId).gyro;
    detect = detected(accId).trial(trialId).filter5;
    
    diff = zeros(length(mag), 3);
    
    for t = 1:length(mag.sample)-1
        diff(t, :) = mag.sample(t, :) - mag.inferMag(t, :);
    end
   
    subplot(nRow, nCol, cnt)
    hold on
    plot(mag.sample)
    if(cnt == 1)
        title(objectName)
    else
        title('magnetometer')
    end
    subplot(nRow, nCol, nCol + cnt)
    hold on
    plot(mag.inferMag)
    title('Infer mag')

    subplot(nRow, nCol, nCol * 2 + cnt)
    hold on
    plot(mag.refInferMag)
    title('Infer mag using previous mag')
    
    subplot(nRow, nCol, nCol * 3 + cnt)
    hold on
    plot(detect)
    title('detected (filter5)')

    subplot(nRow, nCol, nCol * 4 + cnt)
    hold on
    plot(diff)
    title('diff')
    cnt = cnt+1;
end
