function [q, cumQ] = func_quat_from_gyro(sample, rate)

q = zeros(length(sample), 4);
cumQ = zeros(size(q));
for cnt = 2:length(sample)
    theta = (1/rate) * norm(sample(cnt, :));
    v = sample(cnt, :) / norm(sample(cnt, :)) * sin(theta/2);
    cur = quaternion(cos(theta/2), v(1), v(2), v(3)); 
    
    if cnt == 2
        cumulated = cur;
    else
        cumulated = cumulated * cur;
    end
    
    q(cnt, :) = cur.compact();
    cumQ(cnt, :) = cumulated.compact();
end

end