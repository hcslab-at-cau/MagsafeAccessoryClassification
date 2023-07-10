clear;

rawInclude = true;
path = '../Data/';
datasetName = 'default_dataset';
folderName = 'jaemin6';

path = [path, datasetName, '/', folderName];

c = {'Normal_objects', 'Holders'};
postfix = char(c);

% Phyphox version
data = load_data(path, postfix);

% New app version
% data = new_load_data(path, postfix);