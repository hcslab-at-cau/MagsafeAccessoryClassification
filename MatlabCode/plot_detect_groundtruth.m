accId = 1;
showTrials = 3:4;

nCol = length(showTrials);
nRow = 1;

figure(24)
clf


for cnt = 1:length(showTrials)
    tmp = data(accId).trial(showTrials(cnt));
    rmag =tmp.mag;
    gyro = tmp.gyro;
    acc =tmp.acc;
    mag = tmp.mag;
    detect = detected(accId).trial(showTrials(cnt)).filter6;
    gdetect = tmp.detect.sample;
    
    subplot(nRow, nCol, cnt)
    hold on
    plot(rmag.diffSum)
    stem(gdetect, rmag.diffSum(gdetect), 'filled')
    stem(find(detect), rmag.diffSum(detect), 'LineStyle', 'none', 'Marker','*')
    legend({'Feature(diff)', 'Ground-truth', 'Estimated'})


    % subplot(nRow, nCol, cnt)
    % hold on
    % plot(rmag.diff)
    % stem(gdetect, rmag.diff(gdetect), 'filled')
    % stem(find(detect), rmag.diff(detect), 'LineStyle', 'none')
    % legend({'x', 'y', 'z', 'Ground-truth', 'Estimated'})
    % % legend({'x', 'y',' z'})

    % 
    % subplot(nRow, nCol, 3)
    % hold on
    % plot(rmag.sample)
    % 
    % subplot(nRow, nCol, 4)
    % hold on
    % plot(mag.sample)

end