function result = func_predict(label, pred, prob, totalAcc, chargingAcc)
% Assume we know actual label, for identify charging accessorys.

result = pred;


for cnt = 1:size(prob, 1)
    p = prob(cnt, :);

    % Accessory related to charging & Prediction result is related to charging
    if ~isempty(find(ismember(chargingAcc, label(cnt)), 1)) && isempty(find(ismember(chargingAcc, result(cnt)), 1)) 
        % disp(cnt)
        for k = 2:length(p)
            idx = find(p == min(maxk(p, k)));
            
            if idx >= length(totalAcc)
                continue;
            end

            if length(idx) > 1
                chargingIdx = length(find(ismember(chargingAcc, totalAcc(idx))));

                if chargingIdx > 1 || chargingIdx == 0
                    result(cnt) = {'undefined'};
                else
                    result(cnt) = chargingAcc(chargingIdx);
                end
                break;
            end

            pLabel = totalAcc(idx);

            if ~isempty(find(ismember(chargingAcc, pLabel), 1))              
                result(cnt) = pLabel;
                break;
            end
        end
    % Accessory is not related to charging & Prediction result is related to charging
    elseif isempty(find(ismember(chargingAcc, label(cnt)), 1)) && ~isempty(find(ismember(chargingAcc, result(cnt)), 1)) 
        
        for k = 2:length(p)
            idx = find(p == min(maxk(p, k)));

            if idx >= length(totalAcc)
                continue;
            end

            if length(idx) > 1
                chargingIdx = length(find(ismember(chargingAcc, totalAcc(idx))));

                if chargingIdx > 1 || chargingIdx == 0
                    result(cnt) = {'undefined'};
                else
                    result(cnt) = chargingAcc(chargingIdx);
                end
                break;
            end
            
            pLabel = totalAcc(idx);
            if isempty(find(ismember(chargingAcc, pLabel), 1))
 
                result(cnt) = pLabel;
                break;
            end
        end
    end

    idx = find(ismember(totalAcc, result(cnt)));

    % if prob(cnt, idx) < 0.12
    %     result(cnt) = {'non'};
    % end

end


end

