function result = func_load_charging_status(root, postfix)
data = struct();

prevCnt = 0;
cIdx = 1;

for cnt = 1:size(postfix, 1)
    path.root = root;
    path.postfix = deblank(postfix(cnt, :));
    path.data = [path.root '/', path.postfix, '/'];
    
    % Data path for each accessory
    disp(path.data)
    path.accessory = dir(path.data);
    path.accessory(~[path.accessory(:).isdir]) = [];
    path.accessory(ismember({path.accessory(:).name}, {'.', '..'})) = [];

    for cnt2 = prevCnt + (1:length(path.accessory))
        files = dir([path.data, path.accessory(cnt2-prevCnt).name, '/**/*.csv']);

        if isempty(find(contains({files(:).name}, 'Charging'), 1))
            disp(path.accessory(cnt2-prevCnt).name)
            continue
        end
        

        data(cIdx).name = path.accessory(cnt2-prevCnt).name;    
        
        files = dir([path.data, path.accessory(cnt2-prevCnt).name, '/**/*.csv']);

        files(contains({files(:).folder}, 'meta')) = [];
        files(contains({files(:).name}, 'Calibration')) = [];
        indices = find(contains({files(:).name}, 'Charging'));

        for cnt3 = 1:length(indices)
            idx = indices(cnt3);

            tmp = csvread([files(idx).folder, '/', files(idx).name], 1, 0);
            data(cIdx).trial(cnt3).('charging').sample = tmp(:, 1);
        end
        cIdx = cIdx + 1;
    end
    prevCnt = prevCnt + length(path.accessory);
end


result = data;

end