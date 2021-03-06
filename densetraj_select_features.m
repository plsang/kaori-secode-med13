function [ feats ] = densetraj_select_features( descriptor, max_features )
%SELECT_FEATURES Summary of this function goes here
%   Detailed explanation goes here

	%% event_set = 1: 10ex, 2:100Ex, 3: 130Ex
	
    % parameters
	if ~exist('max_features', 'var'),
		max_features = 1000000;
	end
    video_sampling_rate = 1;
	sample_length = 120; % frames
	 
	f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata.mat';
	fprintf('Loading metadata...\n');
	metadata_ = load(f_metadata, 'metadata');
	metadata = metadata_.metadata;
	
    video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
	
	csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	eventbg_csv = 'EVENTS-BG_20130405_ClipMD.csv';
	f_eventvideo_csv = 'EVENTS-130Ex_20130405_ClipMD.csv';

	f_eventvideo_csv = fullfile(csv_dir,f_eventvideo_csv);	
	f_eventbg_csv = fullfile(csv_dir, eventbg_csv);
	
	list_eventvideo = load_video_list(f_eventvideo_csv);
	list_bgvideo = load_video_list(f_eventbg_csv);
	
	list_video = [list_eventvideo, list_bgvideo];
	
	num_selected_videos = ceil(video_sampling_rate * length( list_video ));
	rand_index = randperm(length(list_video));
	selected_index = rand_index(1:num_selected_videos);
    selected_videos = list_video(selected_index);
	
	
	max_features_per_video = ceil(1.05*max_features/length(selected_videos));
	feats = cell(length(selected_videos), 1);
	
    parfor ii = 1:length(selected_videos),
        video_name = selected_videos{ii};
        
        video_file = fullfile(video_dir, metadata.(video_name).ldc_pat);
		start_frame = 1;
        end_frame = metadata.(video_name).num_frames;
		
		if end_frame - start_frame < 15,
			continue;
		end
		
		if end_frame - start_frame > sample_length,
            start_frame = start_frame + randi(end_frame - start_frame - sample_length);
            end_frame = start_frame + sample_length;
        end
		
		fprintf('\n--- [%d/%d] Computing features for video %s ...\n', ii, length(selected_videos), video_name);
		
        feat = densetraj_extract_mbh(video_file, 5, start_frame, end_frame);
        
        if size(feat, 2) > max_features_per_video,
            feats{ii} = vl_colsubset(feat, max_features_per_video);
        else
            feats{ii} = feat;
        end
        
    end
    
    % concatenate features into a single matrix
    feats = cat(2, feats{:});
    
    if size(feats, 2) > max_features,
         feats = vl_colsubset(feats, max_features);
    end

	output_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetrajectory.%s/data/selected_feats_%d_%d.mat', descriptor, max_features);
	output_dir = fileparts(output_file);
	if ~exist(output_dir, 'file'),
		cmd = sprintf('mkdir -p %s', output_dir);
		system(cmd);
	end
	
	fprintf('Saving selected features to [%s]...\n', output_file);
    save(output_file, 'feats', '-v7.3');
    
end


function list_video = load_video_list(csv_file),

	fprintf('--- Loading video from file %s ...\n', csv_file);
	
	fh = fopen(csv_file);
	
	cvs_infos = textscan(fh, '%s %s %s %s %s', 'delimiter', ',');
	clip_ids = cvs_infos{1};
	fclose(fh);
		
	clip_prefix = 'HVC';
	
	list_video = {};
	for ii = 2:length(clip_ids),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		clip_id = str2num(strtrim(strrep(clip_ids{ii}, '"', '')));
	
		clip_name = sprintf('%s%06d', clip_prefix, clip_id);
		
		list_video{end+1} = clip_name;
	end
	
	fprintf('\n');
end
