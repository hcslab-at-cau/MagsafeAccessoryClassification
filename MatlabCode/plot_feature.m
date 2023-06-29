label = [];
for cnt = 1:length(values)
    label = strvcat(label, [values(cnt).name]);
end

colors = [];

figure(3)
clf

for cnt = 1:length(values)
    p = values(cnt).feature;
    
    if cnt > 7
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