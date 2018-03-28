function INV_pipe_fitPatlak_Denoise(opts)
%WIP
load([opts.DCENIIDir '/acqPars']);

%%delete existing output files
delete([opts.DCENIIDir '/PatlakModelFit.nii']);
delete([opts.DCENIIDir '/Patlak_vP.nii']);
delete([opts.DCENIIDir '/Patlak_PSperMin.nii']);

%%read concentration map
Conc4DmMHdr=spm_vol([opts.DCENIIDir '/ConcmM.nii']);
[conc4DmM,temp]=spm_read_vols(Conc4DmMHdr);
dims=[size(conc4DmM,1) size(conc4DmM,2) size(conc4DmM,3)];

MP=load([opts.DCENIIDir '/rDCE.par']);

%%convert 4D to 2D array of time series
conc2DmM=DCEFunc_reshape(conc4DmM);

%%get AIF
AIFMaskData=measure4D(conc4DmM,[opts.DCEROIDir '/' opts.AIFName '.nii']);
Cp_AIF_mM=AIFMaskData.mean/(1-opts.Hct);
save([opts.DCENIIDir '/Cp_AIF_mM'],'Cp_AIF_mM');

%%fit Patlak in a simplified way plus extra regressors
for iFrame=1:acqPars.DCENFrames
IntCp_AIF_mMs(iFrame,1)=sum(Cp_AIF_mM(1:iFrame,1),1) * (acqPars.tRes_s/60);
end

temp=zeros(size(MP));
temp(2:end,:)=MP(1:end-1,:);
MPd=MP-temp;

temp(1:end-1,:)=MP(2:end,:);
MPd2=MP-temp;

reg=[Cp_AIF_mM IntCp_AIF_mMs detrend([MP MP.^2 MPd2 MPd2.^2])];
 %nanmean(conc2DmM,2)
beta = reg \ conc2DmM;

%%fit Patlak model
% [PKP, CtModelFit2D_mM]=DCEFunc_fitModel(acqPars.tRes_s,conc2DmM,Cp_AIF_mM,'Patlak',struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));
% [PKPLinear, CtModelFit2DLinear_mM]=DCEFunc_fitModel(acqPars.tRes_s,conc2DmM,Cp_AIF_mM,'PatlakLinear',struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));
% 
% %%generate 4D image containing model fit values
% SPMWrite4D(Conc4DmMHdr,DCEFunc_reshape(CtModelFit2D_mM,dims),opts.DCENIIDir,'PatlakModelFit',16);
% SPMWrite4D(Conc4DmMHdr,DCEFunc_reshape(CtModelFit2DLinear_mM,dims),opts.DCENIIDir,'PatlakModelLinearFit',16);

%%generate 3D images contain PK parameter values
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(beta(1,:),dims),opts.DCENIIDir,'Patlak_vP',16);
SPMWrite4D(Conc4DmMHdr(1),DCEFunc_reshape(beta(2,:),dims),opts.DCENIIDir,'Patlak_PSperMin',16);

end