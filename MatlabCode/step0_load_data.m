clear;

rawInclude = true;
path = '../Data/';
datasetName = 'Default_dataset';
folderName = 'jaemin8';

path = [path, datasetName, '/', folderName];

% c = {'Normal_objects', 'Holders'};
c = {'Normal_objects', 'Holders'};
postfix = char(c);

% Phyphox version
% data = func_load_data(path, postfix);

% New app version
data = func_load_new_data(path, postfix);