function save_feature(feature, filename)
% tar : struct, contains feature
% filename : file name

save(['../MatlabCode/features/', filename, '.mat'], 'feature');
end