function [result, detectPoints] = func_detection(mag, acc, range, status, t)
result = false;
detectPoints = [];
interval = 100;

% Detection thresholds
magThreshold = 2;
cfarThreshold = .9999;
corrThreshold = .9;
dAngleThreshold = .01;

% High-pass filter args
rate = 100;
order = 4;
[b.magh, a.magh] = butter(order, 10/rate * 2, 'high');
[b.acch, a.acch] = butter(order, 40/rate * 2, 'high');


% Filter 1 : Magnitude > 1
wRange = -100 + range(1):range(end);

if wRange(1) < 1
    wRange = 1:wRange(end);
end

wRangeSize = 1:length(wRange);
magnitude.mag = sum(filtfilt(b.magh, a.magh, mag.sample(wRange, :)).^2, 2);

filter1 = magnitude.mag(wRangeSize(end-99:end)) > magThreshold;
if isempty(find(filter1))
    return
end


% Filter 2 : dAngle > 0.01
filter2 = filter1 & mag.dAngle(range) > dAngleThreshold;
if isempty(find(filter2))
    return
end

% Filter 3 : mag magnitude CFAR 
filter3 = filter2;
for cnt3 = find(filter3)'
    innerRange = 100 + cnt3 + (-100:-1);
    % cnt3
    % innerRange
    % length(magnitude.mag)
    
    % disp([num2str(cnt3), '_', num2str(innerRange(1)), '_', num2str(innerRange(end))])
    if innerRange(end) >= length(magnitude.mag)
        filter3(cnt3) = 0;
    else
        filter3(cnt3) = func_CFAR(magnitude.mag(innerRange), magnitude.mag(innerRange(end)+1), cfarThreshold);
    end
end


if isempty(find(filter3))
    return
end


% Filter 4 : Acc magnitude CFAR
if ~status 
    sp = wRange(1)-5;
    if sp < 1
        sp = 1;
    end

    accRange = sp:wRange(end);
    magnitude.acc = sum(filtfilt(b.acch, a.acch, acc.sample(accRange, :)).^2, 2);
    
    % if t > 1000 && t < 1500
    %     sp
    %     wRange(end)
    % end

    filter4 = filter3;
    for cnt3 = find(filter4)'
        filter4(cnt3) = 0;
        outerRange = cnt3 + (-5:0);
        k = length(accRange)-100;
    
        for cnt4 = outerRange
            point = k+cnt4;
            innerRange = point + (-100:-1);

           
            % disp([num2str(cnt3),'_', num2str(cnt4)])
            % disp(num2str(length(magnitude.acc)))
            % disp(point)
            % disp(cnt3)
            % disp(cnt4)

            if innerRange(1) >= 1 && func_CFAR(magnitude.acc(innerRange), magnitude.acc(point), cfarThreshold)
                filter4(cnt3) = 1;
                break;
            end
        end
    end
    
    if isempty(find(filter4))
        return
    end
end


% Filter 5 : Correlation
if status
    filter5 = filter3;
else
    filter5 = filter4;
end

for cnt = find(filter5)'
    innerRange = range(1) - 1 + cnt + (-5:5);

    if innerRange(1) < 1
        innerRange = 1:innerRange(end);
    end

    if innerRange(end) > t-1
        innerRange = innerRange(1):t-1;
    end

    c = corr(mag.dAngle(innerRange), mag.inferAngle(innerRange));
    filter5(cnt) = c > corrThreshold;
end


if isempty(find(filter5))
    return
end




result = true;
detectPoints = find(filter5)' + range(1) - 1;
end