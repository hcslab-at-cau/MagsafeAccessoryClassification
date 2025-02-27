function res = func_reference_update(ref, params)
o = struct2table(ref);
o = sortrows(o, 'name');
res = table2struct(o);

for cnt = 1:params.data.nObjects
    res(cnt).raw = res(cnt).feature;   
    res(cnt).isChargeable = func_isChargeable(res(cnt).name);
end

end