function result = func_load_new_data(root,postfix)

% Sensor list
dataList = {'acc', 'detect', 'gyro', 'mag', 'rmag', 'time', 'timeRaw'};
sensors = {'acc', 'gyro', 'mag', 'rmag'};
nSensors = length(dataList);
% Load sensor data
data = struct();

prevCnt = 0;

for cnt = 1:size(postfix, 1)
    path.root = root;
    path.postfix = deblank(postfix(cnt, :));
    path.data = [path.root '/', path.postfix, '/'];
    
    % Data path for each accessory
    path.accessory = dir(path.data);
    path.accessory(~[path.accessory(:).isdir]) = [];
    path.accessory(ismember({path.accessory(:).name}, {'.', '..'})) = [];

    for cnt2 = prevCnt + (1:length(path.accessory))
        data(cnt2).name = path.accessory(cnt2-prevCnt).name;    
        
        files = dir([path.data, path.accessory(cnt2-prevCnt).name, '/**/*.csv']);

        files(contains({files(:).folder}, 'meta')) = [];
        files(contains({files(:).name}, 'Calibration')) = [];
        files(contains({files(:).name}, 'Charging')) = [];
        
        for cnt3 = 1:length(files)/nSensors 
            idx = (cnt3 - 1) * nSensors;
    
            for cnt4 = 1:nSensors
                tmp = csvread([files(idx + cnt4).folder, '/', files(idx + cnt4).name], 1, 0);
                
                if max(ismember(sensors, char(dataList(cnt4)))) == 1
                    data(cnt2).trial(cnt3).(char(dataList(cnt4))).sample = tmp(:, 1:3);
                else
                    data(cnt2).trial(cnt3).(char(dataList(cnt4))).sample = tmp(:, 1);
                end
            end
        end
    end
    prevCnt = prevCnt + length(path.accessory);
end


result = data;

end

