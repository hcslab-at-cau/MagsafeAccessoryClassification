clear;

global params;
params = struct();
params.data.newApp = true;
params.data.path = '../Data/Inside_dataset/Jaemin7';
params.data.postfix = char({'310'});

params.data.sensors = {'gyro', 'acc', 'mag'};
params.data.rate = 100;

if params.data.newApp == false
    data = func_load_data(params.data.path, params.data.postfix);
else
    params.data.sensors = [params.data.sensors, 'rmag'];
    data = func_load_new_data(params.data.path, params.data.postfix);
    data = func_timestamp_sync(data);
    
    charging = func_load_charging_status(params.data.path, params.data.postfix);

end

params.objects.name = {'batterypack1', 'griptok1', 'griptok2', 'charger1', 'charger2', 'wallet1',...
    'wallet2', 'wallet3', 'wallet4', 'holder2', 'holder3', 'holder4'};
params.objects.value = [
    -30, 77, -13;
    -56, 108, -115;
    -20, 44, 11;
    -64, 105, -17;
    -25, 55, 8;
    -26, 54, -9;
    -43, 71, 32;
    -51, 34, -9;
    -23, 50, -23;
    -94, 131, -95;
    -22, 41, -12;
    -18, 75, 10
];


for cnt = 1:length(params.objects.name)
    objects(cnt).name = char(params.objects.name(cnt));
    objects(cnt).feature = params.objects.value(cnt, :);
end

objects(~ismember({objects(:).name}, {data.name})) = [];