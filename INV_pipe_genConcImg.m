function INV_pipe_genConcImg(opts)

if opts.overwrite==0 && exist([opts.DCENIIDir '/ConcmM.nii'],'file'); return; end

if ~isfield(opts,'DCEFramesBaseIdx'); opts.DCEFramesBaseIdx=1:opts.DCENFramesBase; end %if indices for baseline are not specified, us all points from 1 to opts.DCENFramesBase

%delete previous outputs
delete([opts.DCENIIDir '/*Enh*.*']); delete([opts.DCENIIDir '/*Conc*.*'])

%load acquisition praameters and 4D realigned image
load([opts.DCENIIDir '/acqPars']);
SI4DHdr=spm_vol([opts.DCENIIDir '/rDCE.nii']);
[SI4D,temp]=spm_read_vols(SI4DHdr);

%%convert 4D to 2D array of time-signal series
SI2D=DCEFunc_reshape(SI4D);

%%load co-registered k map and T1 map; calculate flip angles
[T1Map_s,temp]=spm_read_vols(spm_vol([opts.DCENIIDir '/rT1.nii']));
[kMap,temp]=spm_read_vols(spm_vol([opts.DCENIIDir '/rk.nii']));
FAMap_deg=kMap * acqPars.FA_deg; %scale nominal flip angle using k map
%...and smoothed versions
% [sT1Map_s,temp]=spm_read_vols(spm_vol([opts.DCENIIDir '/srT1.nii']));
% [skMap,temp]=spm_read_vols(spm_vol([opts.DCENIIDir '/srk.nii']));
% sFAMap_deg=skMap * acqPars.FA_deg;

%%calculate enhancement and concentrations
enhancement2DPct=DCEFunc_Sig2Enh(SI2D,opts.DCEFramesBaseIdx);
conc2DmM=DCEFunc_Enh2Conc_SPGR(enhancement2DPct,T1Map_s(:).',acqPars.TR_s,acqPars.TE_s,FAMap_deg(:).',opts.r1_permMperS,opts.r2s_permMperS,opts.Enh2ConcMode);

%%convert back from 2D to 4D images and write
enhancement4DPct=DCEFunc_reshape(enhancement2DPct,[size(SI4D,1) size(SI4D,2) size(SI4D,3)]);
conc4DmM=DCEFunc_reshape(conc2DmM,[size(SI4D,1) size(SI4D,2) size(SI4D,3)]);

%% repeat the above steps using smoothed DCE data (but using unsmoothed T1 and FA maps for now)
sSI4DHdr=spm_vol([opts.DCENIIDir '/srDCE.nii']);
[sSI4D,temp]=spm_read_vols(sSI4DHdr);
sSI2D=DCEFunc_reshape(sSI4D);
sEnhancement2DPct=DCEFunc_Sig2Enh(sSI2D,opts.DCEFramesBaseIdx);
sConc2DmM=DCEFunc_Enh2Conc_SPGR(sEnhancement2DPct,T1Map_s(:).',acqPars.TR_s,acqPars.TE_s,FAMap_deg(:).',opts.r1_permMperS,opts.r2s_permMperS,opts.Enh2ConcMode); %use unsmoothed T1 and k maps
sEnhancement4DPct=DCEFunc_reshape(sEnhancement2DPct,[size(SI4D,1) size(SI4D,2) size(SI4D,3)]);
sConc4DmM=DCEFunc_reshape(sConc2DmM,[size(SI4D,1) size(SI4D,2) size(SI4D,3)]);

paramNames={'EnhPct' 'ConcmM' 'sEnhPct' 'sConcmM'};
outputs={enhancement4DPct conc4DmM sEnhancement4DPct sConc4DmM};
for iOutput=1:size(outputs,2)
    delete([opts.DCENIIDir '/' paramNames{iOutput} '*.*']);
    SPMWrite4D(SI4DHdr,outputs{iOutput},opts.DCENIIDir,paramNames{iOutput},16);
end

end