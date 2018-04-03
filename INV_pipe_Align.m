function INV_pipe_Align(opts)
%align to first volume
%and generate mean pre-contrast image
%this version uses bet to create mask for masking registration

delete([opts.DCENIIDir '/bet*']); delete([opts.DCENIIDir '/rDCE*']); delete('DCE3D*'); delete([opts.DCENIIDir '/meanPre.nii']);

load([opts.DCENIIDir '/acqPars']);

betRefFile=[opts.DCENIIDir '/betDCE3D0000'];
refFile=[opts.DCENIIDir '/DCE3D0000'];

system(['fslsplit ' opts.DCENIIDir '/DCE ' opts.DCENIIDir '/DCE3D -t']); %split 4D file to 3D files
system(['bet ' opts.DCENIIDir '/DCE3D0000 ' betRefFile ' -R -m']); %brain-extract first volume

outFileList=[opts.DCENIIDir '/DCE3D0000'];
for iFrame=2:acqPars.DCENFrames
    inFile=[opts.DCENIIDir '/DCE3D' num2str(iFrame-1,'%04d')];
    inFileBET=[opts.DCENIIDir '/betDCE3D' num2str(iFrame-1,'%04d')];    
    matFile=[opts.DCENIIDir '/rDCE3DMat' num2str(iFrame-1,'%04d') '.txt'];
    outFile=[opts.DCENIIDir '/rDCE3D' num2str(iFrame-1,'%04d')];
    outFileList=[outFileList ' ' outFile];
    system(['flirt -refweight ' betRefFile '_mask -cost normmi '...
        ' -searchrx -30 30 -searchry -30 30 -searchrz -30 30 -coarsesearch 20 -finesearch 6 '...
        ' -in ' inFile ' -ref ' refFile ' -out ' outFile ' -omat ' matFile ' -dof 6']); %calculate transform from this volume to first volume
 
end
system(['fslmerge -t ' opts.DCENIIDir '/rDCE ' outFileList]); %merge co-reg images into 4D file
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rDCE']);

delete([opts.DCENIIDir '/*3D*']); %delete 3D files

SI4DHdr=spm_vol([opts.DCENIIDir '/rDCE.nii']); %load co-reg data to calculate mean pre-contrast image
[SI4D,temp]=spm_read_vols(SI4DHdr);

meanPreContrast=squeeze(mean(SI4D(:,:,:,1:opts.DCENFramesBase),4)); %calculate average pre-contrast image
SPMWrite4D(SI4DHdr,meanPreContrast,opts.DCENIIDir,'meanPre',SI4DHdr(1).dt)

end
