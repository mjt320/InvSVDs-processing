function INV_pipe_fitPatlak(opts)
load([opts.DCENIIDir '/acqPars']);

%%delete existing output files
delete([opts.DCENIIDir '/*Patlak*.nii']);

%%read concentration map
Conc4DmMHdr=spm_vol([opts.DCENIIDir '/ConcmM.nii']);
[conc4DmM,temp]=spm_read_vols(Conc4DmMHdr);
conc2DmMHdr=DCEFunc_reshape(conc4DmM); %convert 4D to 2D array of time series
%...and the smoothed version
sConc4DmMHdr=spm_vol([opts.DCENIIDir '/sConcmM.nii']);
[sConc4DmM,temp]=spm_read_vols(sConc4DmMHdr);
sConc2DmMHdr=DCEFunc_reshape(sConc4DmM); %convert 4D to 2D array of time series

dims=[size(conc4DmM,1) size(conc4DmM,2) size(conc4DmM,3)];

%%get AIF
AIFMaskData=measure4D(conc4DmM,[opts.DCEROIDir '/' opts.AIFName '.nii']);
Cp_AIF_mM=AIFMaskData.mean/(1-opts.Hct);
save([opts.DCENIIDir '/Cp_AIF_mM'],'Cp_AIF_mM');

%%fit Patlak model (non-linear)
%[PKP, CtModelFit2D_mM]=DCEFunc_fitModel(acqPars.tRes_s,conc2DmMHdr,Cp_AIF_mM,'Patlak',struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));
%SPMWrite4D(Conc4DmMHdr,DCEFunc_reshape(CtModelFit2D_mM,dims),opts.DCENIIDir,'PatlakModelFit',16);
%SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKP.vP,dims),opts.DCENIIDir,'Patlak_vP',16);
%SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKP.PS_perMin,dims),opts.DCENIIDir,'Patlak_PSperMin',16);

%%fit Patlak model (linear)
% [PKPLinear, CtModelFit2DLinear_mM]=DCEFunc_fitModel(acqPars.tRes_s,conc2DmMHdr,Cp_AIF_mM,'PatlakLinear',struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));
% SPMWrite4D(Conc4DmMHdr,DCEFunc_reshape(CtModelFit2DLinear_mM,dims),opts.DCENIIDir,'PatlakModelLinearFit',16);
% SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKPLinear.vP,dims),opts.DCENIIDir,'PatlakLinear_vP',16);
% SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKPLinear.PS_perMin,dims),opts.DCENIIDir,'PatlakLinear_PSperMin',16);

%%fit Patlak model (fast linear - smoothed data)
%note the un-smoothed VIF is used to avoid potentially large partial volume effect
[sPKPFast, sCtModelFit2DFast_mM]=DCEFunc_fitModel(acqPars.tRes_s,sConc2DmMHdr,Cp_AIF_mM,'PatlakFast',struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));
SPMWrite4D(sConc4DmMHdr,DCEFunc_reshape(sCtModelFit2DFast_mM,dims),opts.DCENIIDir,'sPatlakModelFastFit',16);
SPMWrite4D(sConc4DmMHdr(1),DCEFunc_reshape(sPKPFast.vP,dims),opts.DCENIIDir,'sPatlakFast_vP',16);
SPMWrite4D(sConc4DmMHdr(1),DCEFunc_reshape(sPKPFast.PS_perMin,dims),opts.DCENIIDir,'sPatlakFast_PSperMin',16);

%%fit Patlak model (fast linear)
[PKPFast, CtModelFit2DFast_mM]=DCEFunc_fitModel(acqPars.tRes_s,conc2DmMHdr,Cp_AIF_mM,'PatlakFast',struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));
SPMWrite4D(Conc4DmMHdr,DCEFunc_reshape(CtModelFit2DFast_mM,dims),opts.DCENIIDir,'PatlakModelFastFit',16);
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKPFast.vP,dims),opts.DCENIIDir,'PatlakFast_vP',16);
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKPFast.PS_perMin,dims),opts.DCENIIDir,'PatlakFast_PSperMin',16);


end