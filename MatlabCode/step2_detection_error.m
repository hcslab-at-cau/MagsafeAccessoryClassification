detectList = struct(); 

for cnt = 1:length(data)
    detectList(cnt).fpCount = 0;
    detectList(cnt).tpCount = zeros(2, 1); 
    for cnt2 = 1:nTrials 
        attach = groundTruth(cnt).trial(cnt2).attach;
        detach = groundTruth(cnt).trial(cnt2).detach;
        detect = detected(cnt).trial(cnt2).filter7;

        cur = struct();
        cur.attachTrue = zeros(length(attach), 1);
        cur.detachTrue = zeros(length(detach), 1);

        cur.attach = 0;
        cur.detach = 0;

        wRange = (-wSize*1:wSize*1);

        % 1. True-postive
        for cnt3 = find(attach)'
            range = cnt3 + wRange;

            if(is_peak(range, detect))
                cur.attach = cur.attach + 1;
                cur.attachTrue(cnt3) = 1;
            end
        end

        for cnt3 = find(detach)'
            range = cnt3 + wRange;

            if(is_peak(range, detect))
                cur.detach = cur.detach + 1;
                cur.detachTrue(cnt3) = 1;
            end
        end
        
        % 2. False-postive
        cur.falsePositive = zeros(length(attach), 1);
        cur.fpCount = 0;
        for cnt3 = find(detect)'
            range = cnt3 + wRange;
        
            if(~is_peak(range, attach) && ~is_peak(range, detach))
                cur.falsePositive(cnt3) = 1;
                cur.fpCount = cur.fpCount + 1;
            end
        end

        detectList(cnt).trial(cnt2) = cur;
        detectList(cnt).fpCount = detectList(cnt).fpCount + cur.fpCount;
        detectList(cnt).tpCount(1) = detectList(cnt).tpCount(1) + cur.attach;
        detectList(cnt).tpCount(2) = detectList(cnt).tpCount(2) + cur.detach;
    end
end

figure(35)
clf

accId = 6;
trials = 8:8;

nRows = 4;
nCols = length(trials);

for cnt = 1:length(trials)
    fp = detectList(accId).trial(trials(cnt));
    g = groundTruth(accId).trial(trials(cnt));
    filter = detected(accId).trial(trials(cnt)).filter7;
    
    subplot(nRows, nCols, cnt)
    hold on
    plot(fp.attachTrue)
    plot(fp.detachTrue)
    legend({'attach', 'detach'})
    title('Trues')

    subplot(nRows, nCols, nCols + cnt)
    hold on
    plot(g.attach)
    plot(g.detach)
    legend({'attach', 'detach'})
    title('ground truth')

    subplot(nRows, nCols, nCols *2 + cnt)
    plot(filter)
    title('Infered filter')

    subplot(nRows, nCols, nCols *3 + cnt)
    plot(fp.falsePositive)
    title('false positive')

end
