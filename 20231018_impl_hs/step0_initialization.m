%% Load sensor data
% clear;

% params.data.path = '../Data/ElectronicDevice/1';
% params.data.postfix = char({'Laptop'});

% params.data.path = '../Data/PublicTransport/1
% params.data.postfix = char({'ktx'});

% params.data.path = '../Data/SameBrand';
% params.data.postfix = char({'1'});
% 
% params.data.path = '../Data/Device/iPhone14Pro';
% params.data.postfix = char({'Normal_objects', 'Holders'});

% params.data.path = '../Data/Mobility/1';
% params.data.postfix = char({'stair'});

% params.data.path = '../Data/Inside/1';
% params.data.postfix = char({'310Stair'});

% params.data.path = '../Data/Orientation/2';
% params.data.postfix = char({'Normal_objects', 'Holders'});

% params.data.path = '../Data/Default/1';
% params.data.postfix = char({'Normal_objects', 'Holders'});

% params.data.path = '../Data/Figure/1';
% params.data.postfix = char({'1'});

% params.data.path = '../Data/User/5';
% params.data.postfix = char({'Normal_objects', 'Holders'});

ori = func_load_new_data(params.data.path, params.data.postfix);
ori = func_timestamp_sync(ori);
    
charging = func_load_charging_status(params.data.path, params.data.postfix);

names = {ori.name};
% ori(strcmp(names, 'None') | strcmp(names, 'charger3') | strcmp(names, 'wallet5')) = [];
ori(strcmp(names, 'None') | strcmp(names, 'wallet3') | strcmp(names, 'holder3')) = [];
% ori(strcmp(names, 'cooler')) = [];
portable = {'batterypack1', 'wallet1', 'wallet2', 'wallet4', 'wallet5', 'griptok1', 'griptok2'};

% ori(~ismember({ori.name}, portable)) = [];

o = struct2table(ori);
o = sortrows(o, 'name');
ori = table2struct(o);

step0_parameter
%% Divide data into events
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

            if cur.detect.sample(cnt3 * 2) + params.data.eventRange > size(cur.acc.sample, 1)
                data(cnt).trial(idx).event.sample(2) = length(range) - (size(cur.acc.sample, 1) - cur.detect.sample(cnt3 * 2));
            end

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
% params.ref.path = 'features/ref_include_detach.mat';
% params.ref.self = false;
% 
% load(params.ref.path);
% ref = feature;

% if ~params.ref.all
%     ref(~ismember({ref(:).name}, {data.name})) = [];
% end

% o = struct2table(ref);
% o = sortrows(o, 'name');
% ref = table2struct(o);
% 
% for cnt = 1:params.data.nObjects
%     ref(cnt).raw = ref(cnt).feature;   
%     ref(cnt).isChargeable = func_isChargeable(ref(cnt).name);
% end