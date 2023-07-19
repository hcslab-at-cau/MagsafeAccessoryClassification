
attachRange = ((-wSize*3):(fix(wSize/2)));
calRange = 1 + wSize + (-wSize:fix(wSize/2));


accId = 1;


figure(accId + 1)
clf
showTrials = 1:10;

nRow = 5;
nCol = length(showTrials);

for cnt = 1:length(showTrials)
    Fs = 100;                              
    T = 1/Fs;                                 
    
    tmp = data(accId).trial(showTrials(cnt));
    mag = tmp.mag;
    detect = tmp.detect.sample;
    plotCnt = 0;
    
    for cnt2 = 1:2:length(detect)
        range = detect(cnt2) + attachRange;
        L = length(range);
        
        Y = fft(mag.diffSum(range));
        P2 = abs(Y/L);
        P1 = P2(1:L/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        f = Fs*(0:(L/2))/L;

        subplot(nRow, nCol, plotCnt*nCol + cnt)
        plot(f,P1) 
        title("Single-Sided Amplitude Spectrum of X(t)")
        xlabel("f (Hz)")
        ylabel("|P1(f)|")

        plotCnt = plotCnt + 1;
    end
end
