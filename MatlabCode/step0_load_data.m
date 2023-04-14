clear;

% Data path parameters
path.root = '../Data'; 
path.postfix = 'Test_nature1';
path.data = [path.root, '/', path.postfix, '/'];

% Data path for each accessory
path.accessory = dir(path.data);
path.accessory(~[path.accessory(:).isdir]) = [];
path.accessory(ismember({path.accessory(:).name}, {'.', '..'})) = [];

% Sensor list
sensors = {'acc', 'gyro', 'lacc', 'mag'};
nSensors = length(sensors);

% Load sensor data
data = struct();
for cnt = 1:length(path.accessory)
    data(cnt).name = path.accessory(cnt).name;    
    
    files = dir([path.data, path.accessory(cnt).name, '/**/*.csv']);
    files(contains({files(:).folder}, 'meta')) = [];
    
    for cnt2 = 1:length(files)/nSensors 
        idx = (cnt2 - 1) * nSensors;

        for cnt3 = 1:nSensors
            tmp = csvread([files(idx + cnt3).folder, '/', files(idx + cnt3).name], 1, 0);
            
            data(cnt).trial(cnt2).(char(sensors(cnt3))).time = tmp(:, 1);
            data(cnt).trial(cnt2).(char(sensors(cnt3))).sample = tmp(:, 2:4);            
        end
    end
end