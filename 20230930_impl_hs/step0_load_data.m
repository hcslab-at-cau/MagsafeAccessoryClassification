clear;

global params;
params = struct();
params.data.newApp = true;
params.data.path = '../Data/Inside_dataset/Jaemin7';
params.data.postfix = char({'208'});

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