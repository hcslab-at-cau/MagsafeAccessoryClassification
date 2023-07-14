values = struct();
values2 = struct();

for cnt = 1:length(feature)
    value = [];
    value2 = [];
    values(cnt).name = feature(cnt).name;
    values2(cnt).name = feature(cnt).name;

    for cnt2 = 1:nTrials
        cur = feature(cnt).trial(cnt2).cur;
        for cnt3 = 1:length(cur)
            value = [value;cur(cnt3).diff(1, :)];
            value2 = [value2;cur(cnt3).diff(2, :)];
        end 
    end
    values(cnt).feature = value;
    values2(cnt).feature = value2;
end

label = [];
for cnt = 1:length(values)
    label = strvcat(label, [values(cnt).name]);
end

figure(2)
clf

for cnt = 1:length(values)
    p = values2(cnt).feature;
    
    if cnt > 4
        scatter3(p(:,1), p(:,2), p(:,3), 'filled');
    else
        scatter3(p(:,1), p(:,2), p(:,3));
    end
    hold on
end

legend(label)
xlabel('x')
ylabel('y')
zlabel('z')