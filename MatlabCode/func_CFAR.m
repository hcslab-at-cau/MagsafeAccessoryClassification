function result = func_CFAR(ref, cur, threshold)

mu = mean(ref);
sigma = std(ref);

p = normcdf(cur, mu, sigma);

result = p > threshold;

end

