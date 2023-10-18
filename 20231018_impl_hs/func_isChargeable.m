function [isChargeable] = func_isChargeable(name)

isChargeable = false;

switch name
    case {'batterypack1', 'charger1', 'charger2'}
        isChargeable = true;
end
end

