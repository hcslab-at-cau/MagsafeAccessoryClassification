function [flag, probs] = func_predict_diff(mag, gyro, objs, range)

diff = zeros(length(range), 3);


for t = 2:length(range)
    euler = gyro.sample(range(t), :) * 1/100;
    rotm = eul2rotm(euler, 'XYZ');
    
    diff(t, :) = mag.sample(range(t), :) - (rotm\(mag.sample(range(t)-1, :))')';
end

noObjDiff = sum(var(diff));
varArray = [];

for cnt = 1:length(objs)
    obj = objs(cnt);

    samples = mag.sample(range, :) - obj.feature;
    diff = zeros(length(range), 3);
    
    for t = 2:length(range)
        euler = gyro.sample(range(t), :) * 1/100;
        rotm = eul2rotm(euler, 'XYZ');
        
        diff(t, :) = samples(t, :) - (rotm\(samples(t-1, :))')';
    end
    
    varArray(end + 1) = sum(var(diff));
end

minIdx = find(varArray == min(varArray));

if min(varArray) > noObjDiff
    flag = false;
else
    flag = true;
end

varArray = 1 ./ varArray;
probs = varArray / sum(varArray);

end

