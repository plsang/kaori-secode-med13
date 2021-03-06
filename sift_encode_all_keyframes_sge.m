function [ output_args ] = sift_encode_all_keyframes_sge( szPat, sift_algo, param, codebook_size, clustering_algo, dimred, enc_type, spm, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	%Usage:
	%In: 
	%	clustering_algo: kmeans, gmm
	%	dimred: 		 feat dim, default 128, ortherwise using pca
	
	% update: Jun 25th, SPM suported
    % setting
    set_env;

	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s.mat', szPat);
	fprintf('Loading metadata...\n');
	metadata_ = load(f_metadata, 'metadata');
	metadata = metadata_.metadata;
	
	videos = fieldnames(metadata);
	fprintf('--- %d video info loaded...\n', length(videos));
	
    kf_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/keyframes';
	
    fea_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/feature/keyframes';
    if ~exist(fea_dir, 'file'),
        mkdir(fea_dir);
    end
        
    
	if ~exist('enc_type', 'var'),
		enc_type = 'soft';
	end
    
	if ~exist('clustering_algo', 'var'),
		cluster_algo = 'kmeans';
	end
    
	if ~exist('codebook_size', 'var'),
		codebook_size = 4000;
	end
	
	if ~exist('spm', 'var'),
		spm = 0;
	end
	
	default_dim = 128;
	if ~exist('dimred', 'var'),
		dimred = default_dim;
	end
	
	feature_ext = sprintf('%s.%s.sift.cb%d.devel.%s', sift_algo, num2str(param), codebook_size, enc_type);
	if spm > 0,
		feature_ext = sprintf('%s.spm', feature_ext);
	end
	
	if dimred < default_dim,,
		feature_ext = sprintf('%s.pca', feature_ext);
	end
	
    output_dir = sprintf('%s/%s/%s', fea_dir, feature_ext, szPat) ;
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
    
    codebook_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/%s.%s.sift/data/codebook.%s.%d.%d.mat', ...
		sift_algo, num2str(param), clustering_algo, codebook_size, dimred);
		
	fprintf('Loading codebook [%s]...\n', codebook_file);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
 
	
 	low_proj = [];
	if dimred < default_dim,
		lowproj_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/%s.%s.sift/data/lowproj.%d.%d.mat', ...
			sift_algo, num2str(param), dimred, default_dim);
			
		fprintf('Loading low projection matrix [%s]...\n', lowproj_file);
		low_proj_ = load(lowproj_file, 'low_proj');
		low_proj = low_proj_.low_proj;
	end
	
	kdtree = [];
	
	if strcmp('kmeans', clustering_algo),
		kdtree = vl_kdtreebuild(codebook);	
	end
	
	
    if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(videos),
        end_seg = length(videos);
    end
    
    %tic
	
		
    parfor ii = start_seg:end_seg,
        
    
		video_name = videos{ii};
        
		output_file = [output_dir, '/', video_name, '.mat'];
		if exist(output_file, 'file'),
			fprintf('File [%s] already exist. Skipped!!\n', output_file);
			continue;
		end
			
		video_kf_dir = fullfile(kf_dir, metadata.(video_name).ldc_pat);
		video_kf_dir = video_kf_dir(1:end-4);	
        
		kfs = dir([video_kf_dir, '/*.jpg']);

		fprintf(' [%d --> %d --> %d] Extracting & encoding for video [%s - %d kfs]...\n', start_seg, ii, end_seg, video_name, length(kfs));
			
		codes = cell(length(kfs), 1);
		
		for jj = 1:length(kfs),
			if ~mod(jj, 10),
				fprintf('%d ', jj);
			end
			img_name = kfs(jj).name;
			img_path = fullfile(video_kf_dir, img_name);
		
			try
				im = imread(img_path);
			catch
				warning('Error while reading image [%s]!!\n', img_path);
				continue;
			end
			
			[frames, descrs] = sift_extract_features( im, sift_algo, param );
            
            % if more than 50% of points are empty --> possibley empty image
            if sum(all(descrs == 0, 1)) > 0.5*size(descrs, 2),
                warning('Maybe blank image...[%s]. Skipped!\n', img_name);
                continue;
            end
			
			if spm > 0
				code = sift_encode_spm(enc_type, size(im), frames, descrs, codebook, kdtree, low_proj);
			else
				code = sift_do_encoding(enc_type, descrs, codebook, kdtree, low_proj);	
			end
			
			%%             
			codes{jj} = code;
		end
		fprintf('\n');
		% averaging...
		%code = mean(code, 2);
        
		par_save(output_file, codes); % MATLAB don't allow to save inside parfor loop
        
    end
    
    %toc
    quit;

end

function par_save( output_file, codes )
  save( output_file, 'codes');
end

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-med13/log/sift_encode_all_keyframes_sge.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

