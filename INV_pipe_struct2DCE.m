function INV_pipe_struct2DCE(opts)
%co-register structural image to DCE

if opts.overwrite==0 && exist([opts.DCENIIDir '/rStructImage.nii'],'file'); return; end

NROIs=size(opts.ROINames,2); %number of ROIs

%% make output directory and delete existing output files
delete([opts.DCENIIDir '/rStructImage.*']);
delete([opts.DCENIIDir '/struct2DCE.txt']);

%% calculate transformation from structural image (in which masks are defined) and meanPre DCE image
system(['flirt -cost normmi -usesqform -in ' opts.structImagePath ' -ref ' opts.DCENIIDir '/meanPre -out ' [opts.DCENIIDir '/rStructImage'] ' -omat ' opts.DCENIIDir '/struct2DCE.txt']); %calculate transformation from structural image to mean pre-contrast DCE image
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rStructImage']); %change to .nii

end
