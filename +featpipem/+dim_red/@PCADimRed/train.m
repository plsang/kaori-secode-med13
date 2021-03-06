function low_proj = train(obj, imlist, prms)
%TRAIN Summary of this function goes here
%   Detailed explanation goes here

% -------------------------------------------------------------------------
% 1. Extract features for training into 'feats' matrix
%     applying any limits on number of features/images
% -------------------------------------------------------------------------

% if trainimage_count was not left at it's default value
% (indicating all detected images should be used for training)
% select a subset of the images
if obj.trainimage_limit > 0
    idxs = 1:length(imlist);
    idxs = vl_colsubset(idxs, obj.trainimage_limit);
    imlist = imlist(idxs);
end

if obj.descount_limit > 0
    % set truncation value for image features just a little bit
    % larger than descount_limit, so if there are any images
    % with fewer than descount_limit/numImages we still have
    % some chance of getting descount_limit descriptors in the end
    img_descount_limit = ceil(obj.descount_limit / ...
        length(imlist) * 1.1);
    fprintf('Extracting a maximum of %d features from each image...\n', ...
        img_descount_limit);
end

feats = cell(length(imlist),1);

% iterate through images, computing features
pfImcount = length(imlist);
parfor ii = 1:length(imlist)
    %%%fprintf('Computing features for: %s %f %% complete\n', ...
    %%%    imlist{ii}, ii/pfImcount*100.00);

    %%%im = imread(imlist{ii});
    %%%im = featpipem.utility.standardizeImage(im);
    %%%feats_all = obj.featextr.compute(im); %#ok<PFBNS>
    
    [imgpath imgid] = fileparts(imlist{ii});
    feainfo = prms.imdb.feadirs(imgid);
    feapath = sprintf('%s/%s/%s/%s.nsc.raw.dense6.sift.tar.gz', prms.feadir, feainfo{1}, feainfo{2}, imgid);
    fprintf('Reading features from: %s\n',feapath);
    feats_all = read_feature(feapath, obj.featextr);
    
    % if a descount limit applies, discard a fraction of features now to
    % save memory
    if obj.descount_limit > 0
        feats{ii} = vl_colsubset(feats_all, ...
                 img_descount_limit);
    else
        feats{ii} = feats_all;
    end
end
clear feats_all;
% concatenate features into a single matrix
feats = cat(2, feats{:});

extractedFeatCount = size(feats,2);
fprintf('%d features extracted\n', extractedFeatCount);

if obj.descount_limit > 0
    % select subset of features for training
    feats = vl_colsubset(feats, obj.descount_limit);
    % output status message
    fprintf('%d features will be used for PCA (%f %%)\n', ...
        obj.descount_limit, obj.descount_limit/extractedFeatCount*100.0);
end

% -------------------------------------------------------------------------
% 2. Perform PCA on the samples
% -------------------------------------------------------------------------

fprintf('Performing PCA...\n');

low_proj = princomp(feats');
low_proj = low_proj(:, 1:obj.dim)';

fprintf('Done learning dimensionality reduction!\n');

end

