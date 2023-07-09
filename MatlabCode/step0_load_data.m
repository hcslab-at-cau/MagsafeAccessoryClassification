clear;

rawInclude = true;
path = '../Data/Default_dataset/';
folderName = 'Jaemin7';

path = [path, folderName];

c = {'Normal_objects', 'Holders'};
postfix = char(c);


data = load_data(path, postfix);