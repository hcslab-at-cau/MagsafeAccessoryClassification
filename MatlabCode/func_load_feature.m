function res = load_feature(filename)

res = load(['../MatlabCode/features/', filename, '.mat']);
res = res.feature;

end