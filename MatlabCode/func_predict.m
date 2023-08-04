function [pred, prob, scores] = func_predict(model, testData, chargingAcc, chargingState)
if ~exist('chargingState', 'var')
    chargingState = true;
end

totalAcc = unique(testData.label);
totalAcc{end + 1} = 'non';

[pred, scores] = predict(model, testData.data);

% Get probability of each label
prob = exp(scores) ./ sum(exp(scores),2);

% Consider charging status
if chargingState 
    pred = func_considerCharge(testData.label, pred, prob, totalAcc, chargingAcc);
end

    function result = func_considerCharge(label, pred, prob, totalAcc, chargingAcc)
    result = pred;
    
    for cnt = 1:length(prob)
        p = prob(cnt, :);
        
        % Real accessory related to charging & Prediction result is related to charging
        if ~isempty(find(ismember(chargingAcc, label(cnt)), 1)) && isempty(find(ismember(chargingAcc, result(cnt)), 1)) 
            % disp(cnt)
            for k = 2:length(p)
                pLabel = totalAcc(find(p == min(maxk(p, k))));

                if ~isempty(find(ismember(chargingAcc, pLabel), 1))
                    % disp(['result has been changed 1  ', num2str(result(cnt)), ' to ', num2str(pLabel)])
                    % disp([num2str(cnt), '_ ', num2str(pLabel)])
                    tmp = pLabel;   
                    if length(pLabel) ~= 1
                        for cnt2 = 1:length(pLabel)
                            if ~isempty(find(ismember(chargingAcc, pLabel(cnt2)), 1))
                                tmp = pLabel(cnt2);
                                break;
                            end
                        end
                    end
                    
                    result(cnt) = tmp;
                    break;
                end
            end
        % Real accessory is not related to charging & Prediction result is related to charging
        elseif isempty(find(ismember(chargingAcc, label(cnt)), 1)) && ~isempty(find(ismember(chargingAcc, result(cnt)), 1)) 
            for k = 2:length(p)
                pLabel = totalAcc(find(p == min(maxk(p, k))));
    
                if isempty(find(ismember(chargingAcc, pLabel), 1))
                    % disp(['result has been changed 2  ', num2str(result(cnt)), ' to ', num2str(pLabel)])
                    % disp([num2str(cnt), '_ ', num2str(pLabel)])

                    tmp = pLabel;   
                    if length(pLabel) ~= 1
                        for cnt2 = 1:length(pLabel)
                            if ~isempty(find(ismember(chargingAcc, pLabel(cnt2)), 1))
                                tmp = pLabel(cnt2);
                                break;
                            end
                        end
                        if length(pLabel) ~= 1
                            continue
                        end
                    end
                    
                    result(cnt) = tmp;
                    % result(cnt) = pLabel;
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




end

