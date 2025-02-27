function ref = func_matched_reference(postfix)
% newRef = 'features/ref_include_detach_replace_wallet2.mat';
% oldRef = 'features/ref_include_detach.mat';

newRef = 'templates/reference_replace_wallet2';
oldRef = 'templates/reference';

oldRefPostfixs = {'208', '310Stair', 'subway', '524'};


if sum(strcmp(oldRefPostfixs, postfix)) > 0
    ref = oldRef;
else
    ref = newRef;
end

end