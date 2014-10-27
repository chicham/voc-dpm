function eval_models(path)

load('categories.mat')

for i=1:80
  cls = strtrim(categories(i, :));
  load(sprintf('%s/%s_final.mat', path, cls))
  eval_model(cls, model)
end
