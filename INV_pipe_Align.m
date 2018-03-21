function INV_pipe_Align(opts)
%align to first volume
%and generate mean pre-contrast image

delete([opts.DCENIIDir '/bet*']); delete([opts.DCENIIDir '/rDCE*']); delete('DCE3D*');

load([opts.DCENIIDir '/acqPars']);

refFile=[opts.DCENIIDir '/betDCE3D0000'];

system(['fslsplit ' opts.DCENIIDir '/DCE ' opts.DCENIIDir '/DCE3D -t']);
system(['bet2 ' opts.DCENIIDir '/DCE3D0000 ' refFile]);

outFileList=[opts.DCENIIDir '/DCE3D0000'];
for iFrame=2:acqPars.DCENFrames
    inFile=[opts.DCENIIDir '/DCE3D' num2str(iFrame-1,'%04d')];
    inFileBET=[opts.DCENIIDir '/betDCE3D' num2str(iFrame-1,'%04d')];    
    matFile=[opts.DCENIIDir '/rDCE3DMat' num2str(iFrame-1,'%04d') '.txt'];
    outFile=[opts.DCENIIDir '/rDCE3D' num2str(iFrame-1,'%04d')];
    outFileList=[outFileList ' ' outFile];
    system(['bet2 ' inFile ' ' inFileBET]);
    system(['flirt -cost normmi -in ' inFileBET ' -ref ' refFile ' -omat ' matFile]);
    system(['flirt -applyxfm -in ' inFile ' -ref ' refFile ' -out ' outFile ' -init ' matFile]);
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
