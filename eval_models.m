function eval_models(path)

startup;
global VOC_CONFIG_OVERRIDE;
VOC_CONFIG_OVERRIDE=@ilsvrc_voc_config_override;
load('categories.mat');

for i=1:80
  cls = strtrim(categories(i, :));
  load(sprintf('%s/%s_final.mat', path, cls))
  eval_model(cls, model)
end
