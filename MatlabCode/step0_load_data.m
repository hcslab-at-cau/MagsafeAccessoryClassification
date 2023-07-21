clear;

newApp = false;
path = '../Data/';
datasetName = 'Default_dataset';
folderName = 'Junhyub1';

path = [path, datasetName, '/', folderName];

c = {'Normal_objects', 'Holders'};
% c = {'subway'};
postfix = char(c);

% disp(path)
% Phyphox version
data = func_load_data(path, postfix);

% New app version
% data = func_load_new_data(path, postfix);