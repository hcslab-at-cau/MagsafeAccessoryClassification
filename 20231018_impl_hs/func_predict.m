function pred = func_predict(X, Y ,probs, charging, ref)
pred = {};
labels = {ref.name};

for cnt = 1:length(Y)
    acc = Y(cnt);
    org = X(cnt, :);
    p = probs(cnt, :);
    [~, identified] = sort(p, 'descend');
    flag = find(ismember(charging, acc), 1);
    identified = labels(identified);

    if isempty(flag)
        identified(ismember(identified, charging)) = [];
    else
        identified(~ismember(identified, charging)) = [];
    end

    identified = identified(1);
    
    % KNN Search
    % accessoryRef = ref(find(ismember({ref.name}, identified)));
    % [~, d] = knnsearch(org, accessoryRef.feature);
    % dist = mean(d);
    pred(end + 1) = identified;
    % if dist < 30
    %     pred(end + 1) = identified;
    % else
    %     pred{end + 1} = 'unknown';
    % end
end
end