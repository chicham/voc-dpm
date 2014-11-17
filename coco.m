function coco(n, start, stop)
% Train and evaluate a model. 
%   pascal(n, note, dotrainval, testyear)
%
%   The model will be a mixture of n star models, each of which
%   has 2 latent orientations.
%
% Arguments
%   n             Number of aspect ratio clusters to use
%                 (The final model has 2*n components)
%   note          Save a note in the model.note field that describes this model
%   dotrainval    Also evaluate on the trainval dataset
%                 This is used to collect training data for context rescoring
%   testyear      Test set year (e.g., '2007', '2011')

% AUTORIGHTS
% -------------------------------------------------------
% Copyright (C) 2011-2012 Ross Girshick
% Copyright (C) 2008, 2009, 2010 Pedro Felzenszwalb, Ross Girshick
% 
% This file is part of the voc-releaseX code
% (http://people.cs.uchicago.edu/~rbg/latent/)
% and is available under the terms of an MIT-like license
% provided in COPYING. Please retain this notice and
% COPYING if you use this file (or a portion of it) in
% your project.
% -------------------------------------------------------

startup;
global VOC_CONFIG_OVERRIDE;
VOC_CONFIG_OVERRIDE = @coco_voc_config_override;
conf = voc_config();
testset = conf.eval.test_set;
load('categories.mat')

for i = start:stop

  conf = voc_config();

  % TODO: should save entire code used for this run
  % Take the code, zip it into an archive named by date
  % print the name of the code archive to the log file
  % add the code name to the training note
  timestamp = datestr(datevec(now()), 'dd.mmm.yyyy:HH.MM.SS');

  % Set the note to the training time if none is given
  note = timestamp;

  % Don't evaluate trainval by default
  dotrainval = false;

  testyear = conf.pascal.year;


  % Record a log of the training and test procedure
  cls = strtrim(categories(i, :));
  diary(conf.training.log([cls '-' timestamp]));

  % Train a model (and record how long it took)
  th = tic;
  model = pascal_train(cls, n, note);
  toc(th);

  % Free the feature vector cache memory
  fv_cache('free');

  % Lower threshold to get high recall
  model.thresh = min(conf.eval.max_thresh, model.thresh);
  model.interval = conf.eval.interval;

  suffix = testyear;

  % Collect detections on the test set
  ds = pascal_test(model, testset, testyear, suffix);

  % Evaluate the model without bounding box prediction
  ap1 = pascal_eval(cls, ds, testset, testyear, suffix);
  fprintf('AP = %.4f (without bounding box prediction)\n', ap1)

  % Recompute AP after applying bounding box prediction
  [ap1, ap2] = bboxpred_rescore(cls, testset, testyear, suffix);
  fprintf('AP = %.4f (without bounding box prediction)\n', ap1)
  fprintf('AP = %.4f (with bounding box prediction)\n', ap2)

  % Compute detections on the trainval dataset (used for context rescoring)
  if dotrainval
    trainval(cls);
  end
end
