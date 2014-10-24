function split_info_out = check_split_info_file_integrity(filename, analysis_model, Contrast_List)

if ~isstruct(filename)
    try
        load(filename);
    catch
        error('loading the split file info- The file might be corrupted!');
    end
else
    split_info = filename;
end

if ~isfield(split_info,'TR_MSEC')
    error('Please specify TR in the split info file: %s',filename);
end

analysis_model = upper(analysis_model);
split_info_out = split_info;
switch analysis_model
    case 'LDA'
        if ~isfield(split_info,'drf')
            error('Please specify drf in the split info file: %s',filename);
        end
        if ~isfield(split_info,'type')
            warning('Please specify type in the split info file: %s, automatically type=block is considered for the LDA model',filename);
            split_info_out.type = 'block';
        end
        
    case 'GNB'
        if ~isfield(split_info,'decision_model')
            error('Please specify decision_model in the split info file: %s',filename);
        end
        if ~isfield(split_info,'type')
            warning('Please specify type in the split info file: %s, automatically type=block is considered for the GNB model',filename);
            split_info_out.type = 'block';
        end
    case 'GLM'
        if ~isfield(split_info,'design_mat')
            error('Please specify design_mat in the split info file: %s',filename);
        end
        if ~isfield(split_info,'convolve')
            error('Please specify convolve in the split info file: %s',filename);
        end
    case 'ERCVA'
        if ~isfield(split_info,'onsetlist')
            error('Please specify onsetlist in the split info file: %s',filename);
        end
        if ~isfield(split_info,'Nsplit')
            error('Please specify Nsplit in the split info file: %s',filename);
        end
        if ~isfield(split_info,'WIND')
            error('Please specify WIND in the split info file: %s',filename);
        end
        if ~isfield(split_info,'drf')
            error('Please specify drf in the split info file: %s',filename);
        end
        if ~isfield(split_info,'subspace')
            error('Please specify subspace in the split info file: %s',filename);
        end
        if ~isfield(split_info,'type')
            warning('Please specify type in the split info file: %s, automatically type=event is considered for the erCVA model',filename);
            split_info_out.type = 'event';
        end
    case 'ERGNB'
        if ~isfield(split_info,'onsetlist')
            error('Please specify onsetlist in the split info file: %s',filename);
        end
        if ~isfield(split_info,'Nsplit')
            error('Please specify Nsplit in the split info file: %s',filename);
        end
        if ~isfield(split_info,'WIND')
            error('Please specify WIND in the split info file: %s',filename);
        end
        if ~isfield(split_info,'type')
            warning('Please specify type in the split info file: %s, automatically type=event is considered for the erGNB model',filename);
            split_info_out.type = 'event';
        end
    case 'ERGLM'
        if ~isfield(split_info,'onsetlist')
            error('Please specify onsetlist in the split info file: %s',filename);
        end
        if ~isfield(split_info,'type')
            warning('Please specify type in the split info file: %s, automatically type=event is considered for the erGLM model',filename);
            split_info_out.type = 'event';
        end
    case 'SCONN'
        if ~isfield(split_info,'seed_name')
            error('Please specify seed_name in the split info file: %s',filename);
        end
        if ~isfield(split_info,'spm')
            error('Please specify spm in the split info file: %s',filename);
        end
end



if nargin==3

    % add signle and group field to be used for signle subject or group
    % analysis, for the group analysis we do not need splitting, so it
    % merges the splitting content.

    if isfield(split_info,'idx_cond1_sp1')
        for i = 1:size(Contrast_List,1)
            split_info_out.single.idx_cond(i,1).sp1 = split_info.(sprintf('idx_cond%d_sp1',Contrast_List(i,1)));
            split_info_out.single.idx_cond(i,1).sp2 = split_info.(sprintf('idx_cond%d_sp2',Contrast_List(i,1)));
            split_info_out.single.idx_cond(i,2).sp1 = split_info.(sprintf('idx_cond%d_sp1',Contrast_List(i,2)));
            split_info_out.single.idx_cond(i,2).sp2 = split_info.(sprintf('idx_cond%d_sp2',Contrast_List(i,2)));
            split_info_out.group.idx_cond(i,1).sp   = [split_info_out.single.idx_cond(i,1).sp1 split_info_out.single.idx_cond(i,1).sp2];
            split_info_out.group.idx_cond(i,2).sp   = [split_info_out.single.idx_cond(i,2).sp1 split_info_out.single.idx_cond(i,2).sp2];
        end
    end
    if isfield(split_info,'idx_cond1')
        for i = 1:size(Contrast_List,1)
            split_info_out.group.idx_cond(i,1).sp = split_info.(sprintf('idx_cond%d.sp',Contrast_List(i,1)));
            split_info_out.group.idx_cond(i,2).sp = split_info.(sprintf('idx_cond%d.sp',Contrast_List(i,2)));
        end
    end
end

