accId = 7;
disp(data(accId).name)

trial = 8;
attachInterval = (-wSize*2:wSize/2);

Fs = 100;
T = 1/Fs;
tmp = data(accId).trial(trial);

mag= tmp.mag;
detect = tmp.detect.sample;

figure(accId*10 + trial)
clf

nRow = 1;
nCol = 5;
pCnt = 1;

for cnt = 1:2:length(detect)
    range = detect(cnt) + attachInterval;
    L = length(range);
    pCol = 0;

    % for cnt2 = 1:3
    %     % subplot(nRow, nCol, pCnt + nCol * pCol)
    %     % plot(mag.sample(range, cnt2))
    %     % title(data(accId).name)
    %     % pCol = pCol + 1;
    % 
    %     Y = fft(mag.sample(range, cnt2));
    %     P2 = abs(Y/L);
    %     P1 = P2(1:L/2+1);
    %     P1(2:end-1) = 2*P1(2:end-1);
    %     f = Fs*(0:(L/2))/L;
    % 
    %     subplot(nRow, nCol, pCnt + nCol * pCol)
    %     plot(f,P1)
    %     pCol = pCol + 1;
    %     title([data(accId).name, '_', num2str(cnt2)])
    %     ylim([0, 100])
    %     xlim([0, 5])
    % end

    Y = fft(mag.diffSum(range));
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(L/2))/L;

    subplot(nRow, nCol, pCnt + nCol * pCol)
    plot(f,P1)
    pCol = pCol + 1;
    title([data(accId).name, '_', num2str(cnt2)])
    ylim([0, 100])
    xlim([0, 5])
    pCnt = pCnt + 1;
end