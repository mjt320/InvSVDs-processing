function Q_pipe_struct2QT1_transform(opts)
%co-register structural image to quantitative

if opts.overwrite==0 && exist([opts.niftiDir '/rStructImage.nii'],'file'); return; end

%% make output directory and delete existing output files
delete([opts.niftiDir '/rStructImage.*']);


%% calculate transformation from structural image (in which masks are defined) and meanPre DCE image
system(['flirt -in ' opts.structImagePath ' -ref ' opts.QTargetImagePath ' -out ' [opts.niftiDir '/rStructImage'] ' -init ' opts.niftiDir '/struct2Q.txt -applyxfm']); %apply transform from structural image to target image
system(['fslchfiletype NIFTI ' opts.niftiDir '/rStructImage']); %change to .nii

end
