result = struct();

wSize = 2 * rate;

magThreshold = 1;
cfarThreshold = .9999;
corrThreshold = .5;
dAngleThreshold = .02;


distance = 1 * rate;
rotOrder = 'XYZ';

for cnt = 1:length(data)
    for cnt2 = 1:nTrials
        mag = data(cnt).trial(cnt2).mag;
        gyro = data(cnt).trial(cnt2).gyro;
        
        euler = movsum(gyro.sample, wSize) * 1/rate;
        
        rotated = zeros(length(mag.sample) - wSize, 3);        
        for cnt3 = 1:length(mag.sample) - wSize
            rotm = eul2rotm(euler(cnt3 + wSize / 2, :), rotOrder);
            
            rotated(cnt3, :) = (rotm \ mag.sample(cnt3, :)')';
        end
        
        
        diffM = mag.sample(wSize + 1:end, :) - rotated;
        
        
        subplot 411
        plot(mag.sample)
        
        subplot 412
        plot(gyro.sample)
        
        subplot 413
        plot([zeros(wSize, 3); rotated])
        
        subplot 414
        plot([zeros(wSize, 3); diffM])        
        title(data(cnt).name)
        
        disp('')
    end
end
