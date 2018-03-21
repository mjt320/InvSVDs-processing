function INV_pipe_fitPatlak(opts)
load([opts.DCENIIDir '/acqPars']);

%%delete existing output files
delete([opts.DCENIIDir '/PatlakModelFit.nii']);
delete([opts.DCENIIDir '/Patlak_vP.nii']);
delete([opts.DCENIIDir '/Patlak_PSperMin.nii']);

%%read concentration map
Conc4DmMHdr=spm_vol([opts.DCENIIDir '/ConcmM.nii']);
[conc4DmM,temp]=spm_read_vols(Conc4DmMHdr);
dims=[size(conc4DmM,1) size(conc4DmM,2) size(conc4DmM,3)];

%%convert 4D to 2D array of time series
conc2DmMHdr=DCEFunc_reshape(conc4DmM);

%%get AIF
AIFMaskData=measure4D(conc4DmM,[opts.DCEROIDir '/' opts.AIFName '.nii']);
Cp_AIF_mM=AIFMaskData.mean/(1-opts.Hct);
save([opts.DCENIIDir '/Cp_AIF_mM'],'Cp_AIF_mM');

%%fit Patlak model
[PKP, CtModelFit2D_mM]=DCEFunc_fitModel(acqPars.tRes_s,conc2DmMHdr,Cp_AIF_mM,'Patlak',struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));
[PKPLinear, CtModelFit2DLinear_mM]=DCEFunc_fitModel(acqPars.tRes_s,conc2DmMHdr,Cp_AIF_mM,'PatlakLinear',struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));

%%generate 4D image containing model fit values
SPMWrite4D(Conc4DmMHdr,DCEFunc_reshape(CtModelFit2D_mM,dims),opts.DCENIIDir,'PatlakModelFit',16);
SPMWrite4D(Conc4DmMHdr,DCEFunc_reshape(CtModelFit2DLinear_mM,dims),opts.DCENIIDir,'PatlakModelLinearFit',16);

%%generate 3D images contain PK parameter values
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKP.vP,dims),opts.DCENIIDir,'Patlak_vP',16);
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKP.PS_perMin,dims),opts.DCENIIDir,'Patlak_PSperMin',16);
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKPLinear.vP,dims),opts.DCENIIDir,'PatlakLinear_vP',16);
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(PKPLinear.PS_perMin,dims),opts.DCENIIDir,'PatlakLinear_PSperMin',16);


end