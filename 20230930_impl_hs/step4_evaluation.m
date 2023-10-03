%% Evaluate detection & identification results
params.eval.accMargin = params.data.rate * 3;

for cnt = 1:length(result)
    for cnt2 = 1:length(result(cnt).trial)
        test = result(cnt).trial(cnt2).identify;
        
        cur = struct();
        cur.nTest = size(test.tTest, 1);
        cur.isDetected = false(cur.nTest, 2);
        cur.isIdentified = false(cur.nTest, 2);

        for cnt3 = 1:cur.nTest
            for cnt4 = 1:2
                % Check time instants from ground truth - 3s to ground truth
                range = max(1, test.tTest(cnt3, cnt4) - params.eval.accMargin):...
                    min(length(test.details), test.tTest(cnt3, cnt4));

                % If any kind of event was detected
                if sum(test.details(range) ~= 0) > 0
                    cur.isDetected(cnt3, cnt4) = true;

                    % If correctly identified
                    if (cnt4 == 1 && sum(test.details(range) == result(cnt).class) > 0) || ...
                        (cnt4 == 2 && sum(test.details(range) == length(ref) + 1) > 0)
                        cur.isIdentified(cnt3, cnt4) = true;
                    end
                end
            end
        end

        result(cnt).trial(cnt2).eval = cur;
    end
end

%% Summarize results
summary = struct();
summary.dAcc = zeros(length(result) + 1, 2);
summary.iAcc = zeros(length(result) + 1, 2);
summary.nTest = zeros(length(result) + 1, 1);

for cnt = 1:length(result)
    for cnt2 = 1:length(result(cnt).trial)
        summary.dAcc(cnt, :) = summary.dAcc(cnt, :) + ...
            sum(result(cnt).trial(cnt2).eval.isDetected);

        summary.iAcc(cnt, :) = summary.iAcc(cnt, :) + ...
            sum(result(cnt).trial(cnt2).eval.isIdentified);

        summary.nTest(cnt) = summary.nTest(cnt) + result(cnt).trial(cnt2).eval.nTest;
    end
end

summary.nTest(end) = sum(summary.nTest(1:end - 1));

summary.dAcc(end, :) = sum(summary.dAcc(1:end - 1, :));
summary.iAcc(end, :) = sum(summary.iAcc(1:end - 1, :));

summary.dAcc = summary.dAcc ./ summary.nTest;
summary.iAcc = summary.iAcc ./ summary.nTest;


rowNames = {result(:).name};
rowNames = [rowNames, 'Average'];
colNames = {'Detection (A)', 'Detection (D)', 'Identification (A)', 'Identification (D)'};
disp(array2table([summary.dAcc, summary.iAcc], ...
    'VariableNames', colNames, ...
    'RowNames', rowNames))