function eval_models(path)

startup;
global VOC_CONFIG_OVERRIDE;
VOC_CONFIG_OVERRIDE=@ilsvrc_voc_config_override;
load('categories.mat');

for i=1:80
  cls = strtrim(categories(i, :));
  fname = sprintf('%s/%s_final.mat', path, cls)

  if exist(fname) > 0
    eval_model(cls, model)
  end

end
