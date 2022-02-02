function Q_pipe_struct2QT1_transform(opts)
%co-register structural image to quantitative

if opts.overwrite==0 && exist([opts.niftiDir '/rStructImage.nii'],'file'); return; end

if ~isfield(opts,'structCoRegMode'); opts.structCoRegMode=0; end %use default co-reg mode

%% make output directory and delete existing output files
delete([opts.niftiDir '/rStructImage.*']);

%% calculate transformation from structural image (in which masks are defined) and meanPre DCE image
switch opts.structCoRegMode
    case 0
    system(['flirt -in ' opts.structImagePath ' -ref ' opts.QTargetImagePath ' -out ' [opts.niftiDir '/rStructImage'] ' -init ' opts.niftiDir '/struct2Q.txt -applyxfm']); %apply transform from structural image to target image
    case 4
        system(['tractor reg-apply ' opts.structImagePath ' ' opts.niftiDir '/rStructImage TransformName:' opts.niftiDir '/rStructImage'] );
    otherwise
        error('Struct co-reg mode not recognised.');
end
system(['fslchfiletype NIFTI ' opts.niftiDir '/rStructImage']); %change to .nii

end
