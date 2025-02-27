% params.global.nObjects = 13;

params.global.all = sort({'wallet1', 'wallet2', 'wallet4', 'wallet5', 'griptok1', 'griptok2', 'charger1', 'charger2', 'charger3', ...
    'holder2', 'holder4', 'holder5', 'batterypack1', 'cooler'});

% params.global.all = sort({'wallet1', 'wallet2', 'wallet4', 'wallet5', 'griptok1', 'griptok2', 'charger1', 'charger2', 'charger3', ...
%     'holder2', 'holder4', 'holder5', 'batterypack1'});

params.global.nObjects = length(params.global.all);

params.global.chargable = {'charger1', 'charger2', 'charger3', 'holder2', 'holder4', 'batterypack1'};
params.global.nonChargable = params.global.all(~ismember(params.global.all, params.global.chargable));
params.global.mdl = false;

params.data.newApp = true;
params.data.sensors = {'gyro', 'mag', 'rmag', 'acc'};
params.data.rate = 100;
params.data.pre = false;
params.data.raw = true;

params.data.nObjects = length(ori);

params.data.eventRange = params.data.rate * 5;
params.data.calibRange = params.data.rate * 5;

params.pre.fOrder = 4;
params.pre.fHCut = 10;
params.pre.fLCut = 2.5;
params.pre.movWinSize = params.data.rate * .4;

[params.pre.fHB, params.pre.fHA] = butter(params.pre.fOrder, ...
    params.pre.fHCut/params.data.rate * 2, 'high');

[params.pre.fHBAcc, params.pre.fHAAcc] = butter(params.pre.fOrder, ...
    40/params.data.rate * 2, 'high');

[params.pre.fLB, params.pre.fLA] = butter(params.pre.fOrder, ...
    params.pre.fLCut/params.data.rate * 2, 'low');

params.pre.cRange = 1:params.data.rate * 5; % For raw magnetometer calibration

if params.data.pre
    pre = func_load_new_data('../Data/InsideOffice/1/Pre', char({'sh'}));
    
    [params.pre.calm, params.pre.bias, ~] = magcal(pre(1).trial(1).rmag.sample(1:1500, :));
end

params.detect.magTh = 1;
params.detect.diffTh = 2;

params.detect.margin = params.data.rate * 0.1 * 4 + 1;
params.detect.minDist = params.data.rate * 1;

params.identify.testMargin = params.data.rate * 3;

params.identify.searchRange = params.data.rate * 1;
params.identify.baseRange = params.data.rate * 1;

params.identify.featureRange = params.data.rate * .1;
params.identify.prc = [10, 90];

params.ref.self = false;

if params.ref.self 
    params.identify.nRepeat = 10;
else
    params.identify.nRepeat = 1;
end