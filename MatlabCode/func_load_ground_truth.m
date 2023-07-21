function result = load_ground_truth(dataName, folderName)

% result = struct();
path = ['../Data/', dataName, '/ground_truth/', folderName, '.csv'];

disp(path)
value = readtable(path);

result = value;


end