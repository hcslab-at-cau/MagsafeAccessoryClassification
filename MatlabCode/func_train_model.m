function [model, pred, prob] = func_train_model(templateModel, featureMatrix, chargingAcc)
totalAcc = unique(featureMatrix.test.label);

% Training model
model = fitcecoc(featureMatrix.train.data, featureMatrix.train.label, 'Learners', templateModel);
[pred, scores] = predict(model, featureMatrix.test.data);

% Get probability of each label
prob = exp(scores) ./ sum(exp(scores),2);

% Consider charging status
pred = func_considerCharge(featureMatrix.test.label, pred, prob, totalAcc, chargingAcc);

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
    end
    
    end

end