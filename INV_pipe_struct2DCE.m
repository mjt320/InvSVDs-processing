function INV_pipe_struct2DCE(opts)
%co-register structural image to DCE

if opts.overwrite==0 && exist([opts.DCENIIDir '/rStructImage.nii'],'file'); return; end

if ~isfield(opts,'structCoRegMode'); opts.structCoRegMode=0; end %use default co-reg mode

NROIs=size(opts.ROINames,2); %number of ROIs

%% make output directory and delete existing output files
delete([opts.DCENIIDir '/rStructImage.*']);
delete([opts.DCENIIDir '/struct2DCE.txt']);
if exist([opts.DCENIIDir '/rStructImage.xfmb'],'dir')
    delete([opts.DCENIIDir '/rStructImage.xfmb/*']);
    rmdir([opts.DCENIIDir '/rStructImage.xfmb']);
end

%% calculate transformation from structural image (in which masks are defined) and meanPre DCE image

switch opts.structCoRegMode
    case 0
        system(['flirt -cost normmi -usesqform -in ' opts.structImagePath ' -ref ' opts.DCENIIDir '/meanPre -out ' [opts.DCENIIDir '/rStructImage'] ' -omat ' opts.DCENIIDir '/struct2DCE.txt']); %calculate transformation from structural image to mean pre-contrast DCE image
    case 1
        system(['flirt -cost normmi -finesearch 3 -usesqform -in ' opts.structImagePath ' -ref ' opts.DCENIIDir '/meanPre -out ' [opts.DCENIIDir '/rStructImage'] ' -omat ' opts.DCENIIDir '/struct2DCE.txt']); %calculate transformation from structural image to mean pre-contrast DCE image
%     case 2
%         system(['bet ' opts.structImagePath ' ' opts.DCENIIDir '/betStructImage -R -m']); %brain-extract first volume
%         system(['flirt -cost normmi -usesqform -in ' opts.DCENIIDir '/betStructImage -ref ' opts.DCENIIDir '/betDCE3D0000 -out ' [opts.DCENIIDir '/rStructImage'] ' -omat ' opts.DCENIIDir '/struct2DCE.txt']); %calculate transformation from structural image to mean pre-contrast DCE image
    case 3
        system(['flirt -cost normmi -usesqform -dof 6 -in ' opts.structImagePath ' -ref ' opts.DCENIIDir '/meanPre -out ' [opts.DCENIIDir '/rStructImage'] ' -omat ' opts.DCENIIDir '/struct2DCE.txt']); %calculate transformation from structural image to mean pre-contrast DCE image
    case 4
        system(['tractor reg-linear ' opts.structImagePath ' ' opts.DCENIIDir '/meanPre ' opts.DCENIIDir '/rStructImage'] );
    otherwise
        error('Struct co-reg mode not recognised.');
end

system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rStructImage']); %change to .nii

end
