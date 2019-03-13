function dilatedLabels = erodeLabelledMasks(labelledMask, dilationRadius)

[dists, labels] = bwdist( labelledMask>0 );

if max(labels(:)) == 0,
    labels = ones(size(labels));
end

dilatedBW = imerode(labelledMask>0, strel('disk',dilationRadius));
% dilatedBW = dists < dilationRadius;

dilatedLabels = labelledMask(labels); 

dilatedLabels(~dilatedBW) = 0;
