function INV_pipe_smooth(opts)
%smooth aligned data

if opts.overwrite==0 && exist([opts.DCENIIDir '/srDCE.nii'],'file'); return; end

delete([opts.DCENIIDir '/sr*']); %delete existing output

system(['fslmaths ' opts.DCENIIDir '/rDCE -kernel gauss 2 -fmean ' opts.DCENIIDir '/srDCE']); %apply 2 mm Gaussian smoothing
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/srDCE']); %change to nii

% system(['fslmaths ' opts.DCENIIDir '/rT1 -kernel gauss 2 -fmean ' opts.DCENIIDir '/srT1']);
% system(['fslchfiletype NIFTI ' opts.DCENIIDir '/srT1']);
% 
% system(['fslmaths ' opts.DCENIIDir '/rk -kernel gauss 2 -fmean ' opts.DCENIIDir '/srk']);
% system(['fslchfiletype NIFTI ' opts.DCENIIDir '/srk']);

end
