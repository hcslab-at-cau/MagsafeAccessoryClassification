%% Evaluate detection & identification results
params.eval.accMargin = params.data.rate * 3;
m = zeros(length(ref), length(ref));
acc = {ref.name};

for cnt = 1:length(result.trial)
    test = result.trial(cnt);
    
    cur = struct();
    cur.nEvent = size(test.event, 1);
    cur.isDetected = false(cur.nEvent, 2);
    cur.isIdentified = false(cur.nEvent, 2);
    cAcc = find(ismember(acc, test.name));

    for cnt2 = 1:cur.nEvent % Almostly 1
        for cnt3 = 1:2
            % Check time instants from ground truth - 3s to ground truth
            range = max(1, test.event(cnt2, cnt3) - params.eval.accMargin):...
                min(length(test.detect.all), test.event(cnt2, cnt3));

            % If any kind of event was detected
            if sum(test.detect.all(range) ~= 0) > 0
                cur.isDetected(cnt2, cnt3) = true;

                if cnt3 == 1 && sum(test.identify.id(range) ~= 0) > 0
                    idx = find(test.identify.id(range));
                    v = test.identify.id(range(idx));
                    v = v(v > 0);

                    m(cAcc, v) = m(cAcc, v) + 1;
                end

                % If correctly identified
                if (cnt3 == 1 && sum(test.identify.id(range) == test.class) > 0) || ...
                    (cnt3 == 2 && sum(test.identify.id(range) == params.data.nObjects + 1) > 0)
                    cur.isIdentified(cnt2, cnt3) = true;
                end
            end
        end
    end

    result.trial(cnt).eval = cur;
end

%% Summarize results
summary = struct();
summary.dAcc = zeros(params.data.nObjects + 1, 2);
summary.iAcc = zeros(params.data.nObjects + 1, 2);
summary.nEvent = zeros(params.data.nObjects + 1, 1);

for cnt = 1:length(result.trial)
    cur = result.trial(cnt);    
    if cur.eval.nEvent > 1
        summary.dAcc(cur.class, :) = summary.dAcc(cur.class, :) + sum(cur.eval.isDetected);
        summary.iAcc(cur.class, :) = summary.iAcc(cur.class, :) + sum(cur.eval.isIdentified);
    else
        summary.dAcc(cur.class, :) = summary.dAcc(cur.class, :) + cur.eval.isDetected;
        summary.iAcc(cur.class, :) = summary.iAcc(cur.class, :) + cur.eval.isIdentified;
    end

    summary.nEvent(cur.class) = summary.nEvent(cur.class) + cur.eval.nEvent;
end

summary.nEvent(end) = sum(summary.nEvent(1:end - 1));

summary.dAcc(end, :) = sum(summary.dAcc(1:end - 1, :));
summary.iAcc(end, :) = sum(summary.iAcc(1:end - 1, :));

summary.dAcc = summary.dAcc ./ summary.nEvent;
summary.iAcc = summary.iAcc ./ summary.nEvent;


rowNames = {data(:).name};
rowNames = [rowNames, 'Average'];
colNames = {'Detection (A)', 'Detection (D)', 'Identification (A)', 'Identification (D)'};
disp(array2table([summary.dAcc, summary.iAcc], ...
    'VariableNames', colNames, ...
    'RowNames', rowNames))


%% Confusion matrix
figure(2)
cm = confusionchart(m, {ref.name});