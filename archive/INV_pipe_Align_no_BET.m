function INV_pipe_Align(opts)
%align to first volume (NEED TO ADD IN BET TO IMPROVE ALIGNMENT)
%and generate mean pre-contrast image

delete([opts.DCENIIDir '/bet*']); delete([opts.DCENIIDir '/rDCE*']); delete([opts.DCENIIDir '/DCE3D*']); delete ([opts.DCENIIDir '/mask.nii']);

load([opts.DCENIIDir '/acqPars']);

refFile=[opts.DCENIIDir '/DCE3D0000'];

system(['fslsplit ' opts.DCENIIDir '/DCE ' opts.DCENIIDir '/DCE3D -t']);
%system(['fslchfiletype NIFTI ' refFile]);

% maskHdr=spm_vol([opts.DCENIIDir '/DCE.nii']);
% [mask,temp]=spm_read_vols(maskHdr(1));
% mask(:,1:round(size(mask,2)/2),:)=0;
% mask(:,round(size(mask,2)/2):end,:)=1;
% SPMWrite4D(maskHdr(1),mask,opts.DCENIIDir,'mask',16);


outFileList=refFile;
for iFrame=2:acqPars.DCENFrames
    inFile=[opts.DCENIIDir '/DCE3D' num2str(iFrame-1,'%04d')];
    outFile=[opts.DCENIIDir '/rDCE3D' num2str(iFrame-1,'%04d')];
    outFileList=[outFileList ' ' outFile];
    maskFile=[opts.DCENIIDir '/mask'];
    system(['flirt -cost normmi -in ' inFile ' -ref ' refFile ' -out ' outFile ' -dof 6']);
end
system(['fslmerge -t ' opts.DCENIIDir '/rDCE ' outFileList]);
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rDCE']);

delete([opts.DCENIIDir '/*3D*']);

SI4DHdr=spm_vol([opts.DCENIIDir '/rDCE.nii']);
[SI4D,temp]=spm_read_vols(SI4DHdr);
meanPreContrast=squeeze(mean(SI4D(:,:,:,1:opts.DCENFramesBase),4));
volOut=SI4DHdr(1);
volOut.dim=[SI4DHdr(1).dim(1:3)];
%volOut.dt=[datatype 0];
volOut.fname=[opts.DCENIIDir '/meanPre.nii'];
delete(volOut.fname);
spm_write_vol(volOut,meanPreContrast);

end
