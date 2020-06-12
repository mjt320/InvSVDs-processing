function INV_pipe_fitPatlak(opts)
load([opts.DCENIIDir '/acqPars']);

if opts.overwrite==0 && exist([opts.DCENIIDir '/PatlakFast_PSperMin.nii'],'file'); return; end

%% delete existing output files
delete([opts.DCENIIDir '/*Patlak*.*']);
delete([opts.DCENIIDir '/opts.mat']);
delete([opts.DCENIIDir '/betDCE3D0000_mask_nan']);

%% read concentration map
Conc4DmMHdr=spm_vol([opts.DCENIIDir '/ConcmM.nii']);
[conc4DmM,temp]=spm_read_vols(Conc4DmMHdr);
conc2DmM=DCEFunc_reshape(conc4DmM); %convert 4D to 2D array of time series
%...and the smoothed version
sConc4DmMHdr=spm_vol([opts.DCENIIDir '/sConcmM.nii']);
[sConc4DmM,temp]=spm_read_vols(sConc4DmMHdr);
sConc2DmM=DCEFunc_reshape(sConc4DmM); %convert 4D to 2D array of time series
% get image dimensions
dims=[size(conc4DmM,1) size(conc4DmM,2) size(conc4DmM,3)];

%% measure AIF from concentration image
AIFMaskData=measure4D(conc4DmM,[opts.DCEAIFDir '/' opts.AIFName '.nii']);
Cp_AIF_mM=AIFMaskData.mean/(1-opts.Hct); %convert from blood concentration to Plasma concentration
save([opts.DCENIIDir '/Cp_AIF_mM'],'Cp_AIF_mM'); %save AIF

%% fit Patlak model (fast linear) and write fitted concentration and parameter maps
[PKPFast, CtModelFit2DFast_mM]=DCEFunc_fitModel(acqPars.tRes_s,conc2DmM,Cp_AIF_mM,'PatlakFast',struct('NIgnore',opts.NIgnore));
SPMWrite4D(Conc4DmMHdr,DCEFunc_reshape(CtModelFit2DFast_mM,dims),opts.DCENIIDir,'PatlakModelFastFit',16);
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKPFast.vP,dims),opts.DCENIIDir,'PatlakFast_vP',16);
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKPFast.PS_perMin,dims),opts.DCENIIDir,'PatlakFast_PSperMin',16);
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKPFast.vP/(1-opts.Hct),dims),opts.DCENIIDir,'PatlakFast_vB',16);
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape((PKPFast.PS_perMin*(1-opts.Hct))./PKPFast.vP,dims),opts.DCENIIDir,'PatlakFast_k_perMin',16);

%% fit Patlak model (fast linear - smoothed data)
%note the un-smoothed VIF is used to avoid potentially large partial volume effect
[sPKPFast, sCtModelFit2DFast_mM]=DCEFunc_fitModel(acqPars.tRes_s,sConc2DmM,Cp_AIF_mM,'PatlakFast',struct('NIgnore',opts.NIgnore));
SPMWrite4D(sConc4DmMHdr,DCEFunc_reshape(sCtModelFit2DFast_mM,dims),opts.DCENIIDir,'sPatlakModelFastFit',16);
SPMWrite4D(sConc4DmMHdr(1),DCEFunc_reshape(sPKPFast.vP,dims),opts.DCENIIDir,'sPatlakFast_vP',16);
SPMWrite4D(sConc4DmMHdr(1),DCEFunc_reshape(sPKPFast.PS_perMin,dims),opts.DCENIIDir,'sPatlakFast_PSperMin',16);
SPMWrite4D(sConc4DmMHdr(1),DCEFunc_reshape(sPKPFast.vP/(1-opts.Hct),dims),opts.DCENIIDir,'sPatlakFast_vB',16);
SPMWrite4D(sConc4DmMHdr(1),DCEFunc_reshape((sPKPFast.PS_perMin*(1-opts.Hct))./sPKPFast.vP,dims),opts.DCENIIDir,'sPatlakFast_k_perMin',16);

%% mask parameter maps (for display purposes)
spm_imcalc([opts.DCENIIDir '/betDCE3D0000_mask.nii'],[opts.DCENIIDir '/betDCE3D0000_mask_nan.nii'],'i1.*(i1./i1)',struct('dtype',16));
filesToMask={'PatlakFast_vP' 'PatlakFast_PSperMin' 'PatlakFast_vB' 'PatlakFast_k_perMin' 'sPatlakFast_vP' 'sPatlakFast_PSperMin' 'sPatlakFast_vB' 'sPatlakFast_k_perMin' };
for iFile=1:size(filesToMask,2)
    system(['fslmaths ' opts.DCENIIDir '/' filesToMask{iFile} ' -mul ' opts.DCENIIDir '/betDCE3D0000_mask_nan ' opts.DCENIIDir '/bet_' filesToMask{iFile}]);
    system(['fslchfiletype NIFTI ' opts.DCENIIDir '/bet_' filesToMask{iFile}]);
end

save([opts.DCENIIDir '/opts'],'opts');

end