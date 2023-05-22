function result = is_peak(range, target)
% Range 범위 내에서 target의 값이 0이 아닌 값이 있는 경우 1 아니면 0

if range(1) < 0
    range = 1:range(end);
end

if range(end) > length(target)
    range = range(1):length(target);
end

index = find(target(range, :))';

result = ~isempty(index);

end