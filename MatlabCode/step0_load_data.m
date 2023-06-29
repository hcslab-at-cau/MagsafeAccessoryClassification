clear;

path = '../Data/Default_dataset/Jaemin6';

c = {'Normal_objects', 'Holders'};
postfix = char(c);

data = load_data(path, postfix);