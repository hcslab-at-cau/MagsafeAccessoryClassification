
tic
nObjs = length(objectFeature);
diff = struct();
parfor cnt = 1:length(data)
    for cnt2 = 1:nTrials
        mag = data(cnt).trial(cnt2).mag;
        lSamples = length(mag.sample);
        
        for cnt3 = 1:nObjs
            inferred = mag.sample;            
            
            for cnt4 = 2:lSamples                
                inferred(cnt4, :) = quatrotate(mag.q(cnt4, :), mag.sample(cnt4 - 1, :) - objectFeature(cnt3).feature);
            end
                                                           
            diff(cnt).trial(cnt2).obj(cnt3).value = mag.sample - objectFeature(cnt3).feature - inferred;
        end
    end
end
toc

%%
target = 5;
trial = 1;

clf
subplot(nObjs + 1, 1, 1)
plot(data(target).trial(trial).mag.diff)
title(['Diff for ', data(target).name])
ylim([-20, 20])

for cnt = 1:nObjs
    subplot(nObjs + 1, 1, cnt + 1)
    plot(diff(target).trial(trial).obj(cnt).value);
    ylim([-20, 20])
    title(['diff with bias subtraction (', objectFeature(cnt).name, ' ', num2str(objectFeature(cnt).feature), ')'])
end
