clear;

rawInclude = true;
path = '../Data/';
datasetName = 'Trivial';
folderName = '20230711';

path = [path, datasetName, '/', folderName];

% c = {'Normal_objects', 'Holders'};
c = {'tmp'};
postfix = char(c);

% Phyphox version
%data = load_data(path, postfix);

% New app version
data = new_load_data(path, postfix);