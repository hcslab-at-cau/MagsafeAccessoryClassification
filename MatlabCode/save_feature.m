function save_feature(feature, filename)
% tar : struct, contains feature
% filename : file name

save([filename, '.mat'], 'feature');
end