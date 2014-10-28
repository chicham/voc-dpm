function eval_model(cls, model)

conf = voc_config();
testset = conf.eval.test_set;
dotrainval = false;
testyear = conf.pascal.year;
suffix = testyear;

% Collect detections on the test set
ds = pascal_test(model, testset, testyear, suffix);

% Evaluate the model without bounding box prediction
ap1 = pascal_eval(cls, ds, testset, testyear, suffix);
fprintf('AP = %.4f (without bounding box prediction)\n', ap1)

% Recompute AP after applying bounding box prediction
[ap1, ap2] = bboxpred_rescore(cls, testset, testyear, suffix, model);
fprintf('AP = %.4f (without bounding box prediction)\n', ap1)
fprintf('AP = %.4f (with bounding box prediction)\n', ap2)

% Compute detections on the trainval dataset (used for context rescoring)
if dotrainval
  trainval(cls);

end
