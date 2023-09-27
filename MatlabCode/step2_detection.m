detected = struct();

params.detect.magTh = 5;
params.detect.cfarTh = .999999;
params.detect.angTh = .01;

params.detect.initRange = params.pre.cRange;
params.detect.cfarWinSize = params.data.rate * 1;

params.detect.accMargin = 5;

corrThreshold = .5;

parfor cnt = 1:length(data) 
    for cnt2 = 1:length(data(cnt).trial)
        mag = data(cnt).trial(cnt2).rmag;
        acc = data(cnt).trial(cnt2).acc;
        gyro = data(cnt).trial(cnt2).gyro;

        range = 1:min([length(mag.magnitude), length(acc.magnitude), ...
            length(mag.dAngle), length(gyro.dAngle)]);

        cur = struct();
        % Filter 1 : the magnitude of mag should be large  enough
        cur.filter.mag = mag.magnitude(range) > params.detect.magTh;
               
        % Filter 2 : the delta angle measured from mag should be large enough               
        cur.filter.ang = mag.dAngle(range) > params.detect.angTh;
        
        % Filter 3 : There should be sudden variation in the magnitude of mag
        cur.filter.mCFAR = zeros(size(cur.filter.mag));
        for cnt3 = params.detect.cfarWinSize + 1:range(end)
            cur.filter.mCFAR(cnt3) = func_CFAR(mag.magnitude(cnt3 + (-params.detect.cfarWinSize:-1)), ...
                mag.magnitude(cnt3), params.detect.cfarTh);     
        end
        
        % Filter 4 : There should be sudden variation in the magnitude of acc
        cur.filter.aCFAR = zeros(size(cur.filter.mag));
        for cnt3 = params.detect.cfarWinSize + 1:range(end)
            cur.filter.aCFAR(cnt3) = func_CFAR(acc.magnitude(cnt3 + (-params.detect.cfarWinSize:-1)), ...
                acc.magnitude(cnt3), params.detect.cfarTh);     
        end
        
        detected(cnt).trial(cnt2) = cur;
    end
end
        
%         for cnt3 = params.detect.accMargin + 1:range(end)
%             cur.filter.aCFAR = logical(movsum(cur.filter.aCFAR, params.detect.accMargin));
%         end
%         
        
%         cur.filter4 = cur.filter3;
%         for cnt3 = find(cur.filter4)'
%             wrange = cnt3 + (-5:0);
%             cur.filter4(cnt3) = 0;
% 
%             for cnt4 = wrange
%                 range = cnt4 + (-wSize:-1);
% 
%                 if range(1) < 1
%                     range = 1:range(end);
%                 end
% 
%                 if(func_CFAR(acc.magnitude(range), acc.magnitude(cnt4), cfarThreshold))
%                     cur.filter4(cnt3) = 1;
%                     break;
%                 end
%             end
%             
%             
%             % cur.filter4(cnt3) = func_CFAR(acc.magnitude(range), ...
%             %     acc.magnitude(cnt3), cfarThreshold);
%         end
% 
%         % Filter 5 : the delta angles measured from mag and gyro should be
%         % different to each other
%         cur.filter5 = cur.filter4;
%         %cur.filter6 = cur.filter4;
% %         for cnt3 = find(cur.filter5)'
% %             % range = cnt3 + 1 + (-wSize:-1);
% %             
% %             cur.filter5(cnt3) = corrData(1, cnt3) > 0.9;
% %             %cur.filter6(cnt3) = corrData(2, cnt3) > 0.5;
% %             % range = cnt3-10 + 1:cnt3+10;
% %             % cur.filter5(cnt3) = corr(mag.dAngle(range), gyro.dAngle(range)) > corrThreshold;
% %         end
% 
%         % Filter 6 : 0.5s 내 1개.
%         cur.filter6 = cur.filter5;
%         for cnt3 = find(cur.filter6)'
%             range = cnt3 + (-wSize:-1);
%             
%             if max(cur.filter6(range)) == 1
%                 cur.filter6(cnt3) = 0;
%             end
%         end
% 
%         detected(cnt).trial(cnt2) = cur;
%         
%         figure;
%         subplot 211
%         plot(mag.magnitude)
%         
%         subplot 212
%         plot(cur.filter6)
%     end
% end

% figure(55)
% clf
% 
% idx = 1;
% cur = data(idx);
% 
% showTrials =1:1;
% nRow = 6;
% nCol = length(showTrials);
% 
% for cnt = 1:length(showTrials)
%     mag = cur.trial(showTrials(cnt)).mag;
%     acc = cur.trial(showTrials(cnt)).acc;
%     gyro = cur.trial(showTrials(cnt)).gyro;
% 
%     range = 1:length(detected(idx).trial(showTrials(cnt)).filter1);        
% 
%     subplot(nRow, nCol, cnt)
%     hold on
%     plot(mag.magnitude)              
%     stem(range(detected(idx).trial(showTrials(cnt)).filter1), ...
%         mag.magnitude(detected(idx).trial(showTrials(cnt)).filter1), 'LineStyle', 'none');    
% 
%     if cnt == 1
%         title([cur.name, ' (mag > 1)'])
%     else
%         title('mag > 1')
%     end
% 
%     subplot(nRow, nCol, nCol + cnt)
%     hold on
%     plot(mag.dAngle)
%     stem(range(detected(idx).trial(showTrials(cnt)).filter2), ...
%         mag.dAngle(detected(idx).trial(showTrials(cnt)).filter2), 'LineStyle', 'none');
%     title('Delta angle > .02')
% 
%     subplot(nRow, nCol, 2 * nCol + cnt)
%     hold on
%     plot(mag.magnitude)
%     stem(range(detected(idx).trial(showTrials(cnt)).filter3), ...
%         mag.magnitude(detected(idx).trial(showTrials(cnt)).filter3), 'LineStyle', 'none');
%     title('mag cfar (.9999)')
% 
%     subplot(nRow, nCol, 3 * nCol + cnt)
%     hold on
%     plot(acc.magnitude)
%     stem(range(detected(idx).trial(showTrials(cnt)).filter4), ...
%         acc.magnitude(detected(idx).trial(showTrials(cnt)).filter4), 'LineStyle', 'none');
%     title('acc cfar (.9999)')
% 
%     subplot(nRow, nCol, 4 * nCol + cnt)    
%     hold on
%     plot(mag.dAngle)
%     plot(gyro.dAngle)
%     title('Delta angle')
%     legend({'Mag', 'Gyro'})
% 
%     % subplot(nRow, nCol, 5 * nCol + cnt)    
%     % hold on
%     % 
%     % corrData = zeros(1, length(range));
%     % for cnt2 = wSize + 1:length(corrData)
%     %     curRange = cnt2 - wSize + 1:cnt2;
%     %     corrData(cnt2) = corr(mag.dAngle(curRange), gyro.dAngle(curRange));
%     % end    
%     % plot(corrData)
%     % 
%     % if sum(detected(idx).trial(showTrials(cnt)).filter5 > 0)
%     %     stem(range(detected(idx).trial(showTrials(cnt)).filter5), ...
%     %         corrData(detected(idx).trial(showTrials(cnt)).filter5), ...
%     %         'LineStyle', 'none');
%     % end
%     % title('corr < .5')
% end