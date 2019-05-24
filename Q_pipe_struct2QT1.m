function Q_pipe_struct2QT1(opts)
%co-register structural image to quantitative

if opts.overwrite==0 && exist([opts.niftiDir '/rStructImage.nii'],'file'); return; end

NROIs=size(opts.ROINames,2); %number of ROIs

%% make output directory and delete existing output files
delete([opts.niftiDir '/rStructImage.*']);
delete([opts.niftiDir '/struct2Q.txt']);

%% calculate transformation from structural image (in which masks are defined) and meanPre DCE image
system(['flirt -cost normmi -usesqform -in ' opts.structImagePath ' -ref ' opts.QTargetImagePath ' -out ' [opts.niftiDir '/rStructImage'] ' -omat ' opts.niftiDir '/struct2Q.txt']); %calculate transformation from structural image to target image
system(['fslchfiletype NIFTI ' opts.niftiDir '/rStructImage']); %change to .nii

end
