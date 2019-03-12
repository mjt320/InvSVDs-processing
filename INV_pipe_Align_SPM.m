function INV_pipe_Align_SPM(opts)
%align to first volume
%and generate mean pre-contrast image
%this version uses bet to create mask for masking registration
%and SPM to realign and reslice

if opts.overwrite==0 && exist([opts.DCENIIDir '/rDCE.nii'],'file'); return; end

%delete existing output files
delete([opts.DCENIIDir '/bet*']); delete([opts.DCENIIDir '/rDCE*']); delete('DCE3D*'); delete([opts.DCENIIDir '/meanPre.nii']); delete([opts.DCENIIDir '/*.txt']);

betRefFile=[opts.DCENIIDir '/betDCE3D0000']; %filename for bet-ed image
refFile=[opts.DCENIIDir '/DCE3D0000'];

system(['fslsplit ' opts.DCENIIDir '/DCE ' opts.DCENIIDir '/DCE3D -t']); %split 4D file to 3D files
system(['bet ' opts.DCENIIDir '/DCE3D0000 ' betRefFile ' -R -m']); %brain-extract first volume
fslchfiletype_all([opts.DCENIIDir '/*DCE3D*.*'],'NIFTI');


imgNames=sort(getMultipleFilePaths([opts.DCENIIDir '/DCE3D*.nii']));

%use SPM to realign volumes
spm_realign(char(imgNames),struct('quality',1,'fwhm',2,'sep',2,'rtm',0,'PW',[betRefFile '_mask.nii'],'interp',3));
spm_reslice(char(imgNames),struct('mask',1,'mean',0,'interp',4,'which',2,'wrap',[0 0 0],'prefix','r'));

spm_file_merge(sort(getMultipleFilePaths([opts.DCENIIDir '/rDCE3D*.nii'])),[opts.DCENIIDir '/rDCE.nii'],0); %merge into 4D file

delete([opts.DCENIIDir '/DCE3D*.nii']); %delete 3D files
delete([opts.DCENIIDir '/rDCE3D*.nii']); %delete 3D files

SI4DHdr=spm_vol([opts.DCENIIDir '/rDCE.nii']); %load co-reg data to calculate mean pre-contrast image
[SI4D,temp]=spm_read_vols(SI4DHdr);

meanPreContrast=squeeze(mean(SI4D(:,:,:,1:opts.DCENFramesBase),4)); %calculate average pre-contrast image
SPMWrite4D(SI4DHdr,meanPreContrast,opts.DCENIIDir,'meanPre',SI4DHdr(1).dt)

end
