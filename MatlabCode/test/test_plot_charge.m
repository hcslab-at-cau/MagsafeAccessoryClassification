% Only related to charging
chargingAcc = {charging(:).name};
totalAcc = {data(:).name};

accName = 'holder3';
showTrials = 1:1;

fig = figure('Name', 'diff values');
fig.Position(3:4) = [1200, 300];
clf
nRow = 1;
nCol = length(showTrials);

cIdx = find(ismember(chargingAcc ,accName));
aIdx = find(ismember(totalAcc, accName));

for cnt = 1:length(showTrials)
    tmp = data(aIdx).trial(showTrials(cnt));
    chargeTime = charging(cIdx).trial(showTrials(cnt)).charging.sample;
    detect = tmp.detect.sample;
    filter = detected(aIdx).trial(showTrials(cnt)).filter6;
    mag = tmp.mag;


    subplot(nRow, nCol, cnt)
    hold on
    plot(mag.diffSum)
    stem(detect, mag.diffSum(detect), 'filled')
    stem(find(filter), mag.diffSum(filter), 'LineStyle', '-')
    stem(chargeTime, mag.diffSum(chargeTime), 'filled')
    legend({'feature(diff sum)', 'Ground-truth', 'Estimated', 'charge time'})
end