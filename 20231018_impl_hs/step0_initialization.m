%% Load sensor data
clear;

global params;
params = struct();
params.data.newApp = true;
params.data.path = '../Data/Inside_dataset/Jaemin7';
params.data.postfix = char({'208'});

% params.data.path = '../Data/Outside_dataset/Jaemin7';
% params.data.postfix = char({'bus'});

params.data.path = '../Data/Default_dataset/Jaemin10';
params.data.postfix = char({'Normal_objects', 'Holders'});

params.data.sensors = {'gyro', 'mag'};
params.data.rate = 100;
params.data.mType = 'rmag';

if params.data.newApp == false
    params.data.mType = 'mag';
    data = func_load_data(params.data.path, params.data.postfix);
else
    params.data.sensors = [params.data.sensors, 'rmag'];
    data = func_load_new_data(params.data.path, params.data.postfix);
    data = func_timestamp_sync(data);
    
    charging = func_load_charging_status(params.data.path, params.data.postfix);
end

for cnt = 1:length(data)
    if strcmp(data(cnt).name, 'None')
        data(cnt) = [];
        break;
    end
end

%% Load reference feature data
params.ref.path = 'features/Jaemin8_p2p.mat';
params.ref.nData = 50;
params.ref.nSub = 50;
params.ref.nSubData = floor(params.ref.nData / (params.ref.nSub));

load(params.ref.path);
ref = feature;
ref(~ismember({ref(:).name}, {data.name})) = [];

for cnt = 1:length(ref)
    ref(cnt).raw = ref(cnt).feature;   
    ref(cnt).feature = zeros(params.ref.nSub, 3);
    ref(cnt).isChargeable = func_isChargeable(ref(cnt).name);

    % Divide references into subsets
    for cnt2 = 1:params.ref.nSub
        range = (cnt2 - 1) * params.ref.nSubData + (1:params.ref.nSubData);
        if params.ref.nSubData > 1
            ref(cnt).feature(cnt2, :) = mean(ref(cnt).raw(range, :));
        else
            ref(cnt).feature(cnt2, :) = ref(cnt).raw(range, :);
        end
    end
end

step1_preprocessing
step2_detection
step3_identification
step4_evaluation