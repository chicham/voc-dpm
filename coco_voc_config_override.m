function conf = sample_voc_config_override()
% Sample config override file
%
% To use this execute:
%  >> global VOC_CONFIG_OVERRIDE;
%  >> VOC_CONFIG_OVERRIDE = @sample_voc_config_override;

% AUTORIGHTS
% -------------------------------------------------------
% Copyright (C) 2011-2012 Ross Girshick
% 
% This file is part of the voc-releaseX code
% (http://people.cs.uchicago.edu/~rbg/latent/)
% and is available under the terms of an MIT-like license
% provided in COPYING. Please retain this notice and
% COPYING if you use this file (or a portion of it) in
% your project.
% -------------------------------------------------------

PASCAL_YEAR = '2014'

conf.project    = 'cvpr_2015_coco_xp';
conf = cv(conf, 'training.train_set_fg', 'train');
conf = cv(conf, 'training.train_set_bg', 'train');
conf = cv(conf, 'training.cache_byte_limit', 10*2^30);
conf = cv(conf, 'training.cache_example_limit', 100000);
conf = cv(conf, 'training.num_negatives_small', 2000);
conf = cv(conf, 'training.num_negatives_large', 20000);
conf = cv(conf, 'eval.test_set', 'val');
