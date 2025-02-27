%% Evaluate detection & identification results
params.eval.accMargin = params.data.rate * 3;
m = zeros(length(params.global.all), length(params.global.all));
acc = params.global.all;

for cnt = 1:length(result.trial)
    test = result.trial(cnt);
    
    cur = struct();
    cur.nEvent = size(test.event, 1);
    cur.isDetected = false(cur.nEvent, 2);
    cur.isIdentified = false(cur.nEvent, 1);
    cur.fp = 0;
    cAcc = find(ismember(acc, test.name));

    id = test.identify.id;
    flag = false;

    for cnt2 = 1:cur.nEvent % Almostly 1
        for cnt3 = 1:2
            % Check time instants from ground truth - 3s to ground truth
            range = max(1, test.event(cnt2, cnt3) - params.eval.accMargin):...
                min(length(test.detect.all), test.event(cnt2, cnt3));

            % If any kind of event was detected
            if sum(test.detect.all(range) ~= 0) > 0
                cur.isDetected(cnt2, cnt3) = true;
                id(range) = "";
                
                % For confusion matrix
                if cnt3 == 1 && sum(~strcmp(test.identify.id(range), "")) > 0
                    idx = find(~strcmp(test.identify.id(range), ""));
                    v = test.identify.id(range(idx));

                    v = find(ismember(params.global.all, v));
                    v = v(v > 0 & v < params.global.nObjects + 1);
                    m(cAcc, v) = m(cAcc, v) + 1;
                end

                % If correctly identified
                if (cnt3 == 1 && sum(test.identify.id(range) == test.name) > 0)
                    flag = true;
                end
                
                if flag && (cnt3 == 2 && sum(test.identify.id(range) == "NIL") > 0)
                    cur.isIdentified(cnt2) = true;
                end
            end
        end

        cur.fp = sum(~strcmp(id, "") & ~strcmp(id, "WR"));
        cur.fps = [sum(~strcmp(id, "NIL") & ~strcmp(id, "") & ~strcmp(id, "WR")), sum(strcmp(id, "NIL"))];

    end

    result.trial(cnt).eval = cur;
end

%% Summarize results
summary = struct();
summary.dAcc = zeros(params.data.nObjects + 1, 2);
summary.iAcc = zeros(params.data.nObjects + 1, 2);
summary.nEvent = zeros(params.data.nObjects + 1, 1);
summary.fp = zeros(params.data.nObjects + 1, 1);
summary.fps = zeros(params.data.nObjects + 1, 2);

for cnt = 1:length(result.trial)
    cur = result.trial(cnt);

    if cur.eval.nEvent > 1  
        summary.dAcc(cur.class, :) = summary.dAcc(cur.class, :) + sum(cur.eval.isDetected);
        summary.iAcc(cur.class, :) = summary.iAcc(cur.class, :) + sum(cur.eval.isIdentified);
    else
        summary.dAcc(cur.class, :) = summary.dAcc(cur.class, :) + cur.eval.isDetected;
        summary.iAcc(cur.class, :) = summary.iAcc(cur.class, :) + cur.eval.isIdentified;
    end

    summary.fp(cur.class) = summary.fp(cur.class) + cur.eval.fp; 
    summary.fps(cur.class, :) = summary.fps(cur.class, :) + cur.eval.fps;

    summary.nEvent(cur.class) = summary.nEvent(cur.class) + cur.eval.nEvent;
end

summary.nEvent(end) = sum(summary.nEvent(1:end - 1));
summary.fp(end) = sum(summary.fp(1:end-1));
summary.fps(end, :) = sum(summary.fps(1:end - 1, :));

summary.dAcc(end, :) = sum(summary.dAcc(1:end - 1, :));
summary.iAcc(end, :) = sum(summary.iAcc(1:end - 1, :));

summary.dAcc = summary.dAcc ./ summary.nEvent;
summary.iAcc = summary.iAcc ./ summary.nEvent;

summary.fp = summary.fp ./ summary.nEvent;
summary.fps = summary.fps ./ summary.nEvent;

rowNames = {data(:).name};
rowNames = [rowNames, 'Average'];

colNames = {'Detection (A)', 'Detection (D)', 'Identification (A)', 'Identification (D)', 'False Positive', 'FP(A)', 'FP(D)'};
table = array2table([summary.dAcc, summary.iAcc, summary.fp, summary.fps], ...
    'VariableNames', colNames, ...
    'RowNames', rowNames);
disp(table)

% figure(55)
% cm = confusionchart(m, {ref.name});
return;

%% Confusion matrix
figure(55)

if isempty(average)
    cm = confusionchart(m, {ref.name});
else
    cm = confusionchart(m, mdl.ClassNames);
end

% cm = confusionchart(m, mdl.ClassNames);