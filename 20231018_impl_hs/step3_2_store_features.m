feature = struct();

for cnt = 1:length(result)
    feature(cnt).name = result(cnt).name;
    feature(cnt).feature = zeros(length(result(cnt).trial), 3);
    
    for cnt2 = 1:length(result(cnt).trial)
        cur = result(cnt).trial(cnt2).identify;        
        idx = find(cur.details > 0 & cur.details ~= length(ref) + 1);
                
        if ~isempty(idx)
            feature(cnt).feature(cnt2, :) = cur.bias(idx(1), :);               
        else
            feature(cnt).feature(cnt2, :) = [0, 0, 0];
        end
    end
end