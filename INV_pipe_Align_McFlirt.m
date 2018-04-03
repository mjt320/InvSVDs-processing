function INV_pipe_Align_McFlirt(opts)

delete([opts.DCENIIDir '/bet*']); delete([opts.DCENIIDir '/rDCE*']); delete('DCE3D*'); delete([opts.DCENIIDir '/meanPre.nii']); delete([opts.DCENIIDir '/*.par']);

load([opts.DCENIIDir '/acqPars']);

betRefFile=[opts.DCENIIDir '/betDCE3D0000'];
refFile=[opts.DCENIIDir '/DCE3D0000'];

system(['mcflirt -refvol 1 -in ' opts.DCENIIDir '/DCE -out ' opts.DCENIIDir '/rDCE -plots']);
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rDCE']);

SI4DHdr=spm_vol([opts.DCENIIDir '/rDCE.nii']); %load co-reg data to calculate mean pre-contrast image
[SI4D,temp]=spm_read_vols(SI4DHdr);

meanPreContrast=squeeze(mean(SI4D(:,:,:,1:opts.DCENFramesBase),4)); %calculate average pre-contrast image
SPMWrite4D(SI4DHdr,meanPreContrast,opts.DCENIIDir,'meanPre',SI4DHdr(1).dt)

end
