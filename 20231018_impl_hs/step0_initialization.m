%% Load sensor data
clear;

global params;
params = struct();
params.data.newApp = true;
% params.data.path = '../Data/Inside/1';
% params.data.postfix = char({'208'});

% params.data.path = '../Data/PublicTransport/1';
% params.data.postfix = char({'subway'});

% params.data.path = '../Data/Mobility/1';
% params.data.postfix = char({'Stair'});
 
params.data.path = '../Data/Default/1';
params.data.postfix = char({'Normal_objects', 'Holders'});

params.data.sensors = {'gyro', 'mag', 'rmag'};
params.data.rate = 100;

ori = func_load_new_data(params.data.path, params.data.postfix);
ori = func_timestamp_sync(ori);
    
charging = func_load_charging_status(params.data.path, params.data.postfix);

names = {ori.name};
% ori(strcmp(names, 'None') | strcmp(names, 'charger3') | strcmp(names, 'wallet5')) = [];
ori(strcmp(names, 'None') | strcmp(names, 'wallet3') | strcmp(names, 'wallet5')) = [];

%% Divide data into events
params.data.nObjects = length(ori);

params.data.eventRange = params.data.rate * 5;
params.data.calibRange = params.data.rate * 5;

data = struct();

for cnt = 1:params.data.nObjects
    data(cnt).name = ori(cnt).name;    
    
    idx = 1;
    for cnt2 = 1:length(ori(cnt).trial)
        cur = ori(cnt).trial(cnt2);
        cmag = cur.rmag.sample(1:params.data.calibRange, :);
        
        for cnt3 = 1:length(cur.detect.sample)/2
            range = max(1, cur.detect.sample(cnt3 * 2 - 1) - params.data.eventRange) ...
                :min(size(cur.acc.sample, 1), cur.detect.sample(cnt3 * 2) + params.data.eventRange);
        
            data(cnt).trial(idx).event.sample = [params.data.eventRange + 1, length(range) - params.data.eventRange];
            data(cnt).trial(idx).acc.sample = cur.acc.sample(range, :);
            data(cnt).trial(idx).gyro.sample = cur.gyro.sample(range, :);
            data(cnt).trial(idx).mag.sample = cur.mag.sample(range, :);
            data(cnt).trial(idx).rmag.sample = cur.rmag.sample(range, :);

            data(cnt).trial(idx).rmag.calSample = cmag;
            data(cnt).trial(idx).mag.calSample = zeros(1, params.data.calibRange);
            
            idx = idx + 1;                        
        end
    end
end

%% Load reference feature data
params.ref.path = 'features/ref_new.mat';
params.ref.self = false;

load(params.ref.path);
ref = feature;
ref(~ismember({ref(:).name}, {data.name})) = [];

for cnt = 1:params.data.nObjects
    ref(cnt).raw = ref(cnt).feature;   
    ref(cnt).isChargeable = func_isChargeable(ref(cnt).name);
end

step1_preprocessing
step2_2_identification
step3_evaluation