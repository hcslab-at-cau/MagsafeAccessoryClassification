function results = func_get_all_paths()

parent = '../Data/';
results = struct();

% kinds = {'Inside', 'PublicTransport'};
kinds = {'InsideOffice'};
% kinds = {'Inside', 'Mobility', 'PublicTransport', 'ElectronicDevice'};
% kinds = {'Inside'};
% kinds = {'ElectronicDevice'};
% kinds = {'PublicTransport'};
% kinds = {'Mobility', 'PublicTransport'};

for cnt = 1:length(kinds)
    cur = cell2mat(kinds(cnt));
    
    switch cur
        case 'Inside'
            % child = {'524', '208', '310Stair', 'airport'};
            child = {'310'};
        case 'Mobility'
            child = {'ground', 'stair'};
        case 'PublicTransport'
            % child = {'ktx', 'bus'};
            child = {'subway', 'car', 'train'};
        case 'ElectronicDevice'
            child = {'laptop'};
        case 'InsideOffice'
            child = {'eh', 'jh', 'mh', 'sh'};
    end

    for cnt2 = 1:length(child)
        results(end + 1).root = [parent, cur, '/1'];
        results(end).postfix = cell2mat(child(cnt2));
        % results{end + 1} = [parent, cur, '/1/', cell2mat(child(cnt2))];
    end
end

results(1) = [];
end

