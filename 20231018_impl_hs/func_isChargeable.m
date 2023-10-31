function [isChargeable] = func_isChargeable(name)

isChargeable = false;

switch name
    case {'batterypack1', 'charger1', 'charger2', 'charger3', 'holder2', ... 
            'holder3', 'holder4'}
        isChargeable = true;
end
end