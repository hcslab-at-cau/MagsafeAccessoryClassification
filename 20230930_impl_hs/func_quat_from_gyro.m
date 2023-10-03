function q = func_quat_from_gyro(sample, rate)

q = zeros(length(sample), 4);
for cnt = 2:length(sample)
    theta = (1/rate) * norm(sample(cnt, :));
    v = sample(cnt, :) / norm(sample(cnt, :)) * sin(theta/2);
    cur = quaternion(cos(theta/2), v(1), v(2), v(3)); 
    
    q(cnt, :) = cur.compact();
end

end