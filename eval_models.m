function eval_models(path)


startup;
global VOC_CONFIG_OVERRIDE;
%VOC_CONFIG_OVERRIDE=@ilsvrc_voc_config_override;
load('categories.mat');


conf = voc_config()

for i=1:80
  cls = strtrim(categories(i, :));
  fname = sprintf('%s/%s_final.mat', path, cls)

  if exist(fname) > 0
    load(fname)
    if exist(sprintf('%s/%s/%s/%s_pr_val_2014.mat', conf.paths.base_dir, conf.project, conf.pascal.year, cls)) == 0
      eval_model(cls, model)
    end
  end

end
