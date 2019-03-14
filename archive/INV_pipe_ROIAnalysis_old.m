function INV_pipe_ROIAnalysis(opts)
%note that AIF data is stored in the last entry of arrays, with
%concentration stored as plasma (Cp) values

load([opts.DCENIIDir '/acqPars']);

%% make output directory delete existing output files
mkdir(opts.DCEROIProcDir); delete([opts.DCEROIProcDir '/*.*']);

%% load 4D DCE and other data
SI4D=spm_read_vols(spm_vol([opts.DCENIIDir '/rDCE.nii']));
[T1Map_s,temp]=spm_read_vols(spm_vol([opts.DCENIIDir '/rT1.nii']));
[kMap,temp]=spm_read_vols(spm_vol([opts.DCENIIDir '/rk.nii']));
load([opts.DCENIIDir '/acqPars']);

%% load Patlak maps (for comparison)
%Patlak_vP_map=spm_read_vols(spm_vol([opts.DCENIIDir '/Patlak_vP.nii']));
%Patlak_PSperMin_map=spm_read_vols(spm_vol([opts.DCENIIDir '/Patlak_PSperMin.nii']));

%% derive parameters
NROIs=size(opts.ROINames,2);
NTimePoints=size(SI4D,1);
FAMap_deg=kMap * acqPars.FA_deg;
n=ceil(sqrt(NROIs+1)); %dimension of plots
ROIData.t_S=((1:acqPars.DCENFrames)-0.5)*acqPars.tRes_s; %calculate time at centre of each acquisition relative to start of DCE - used only for plotting
maskNames=[opts.ROINames opts.AIFName];

%% initialise variables
ROIData.SI=nan(acqPars.DCENFrames,NROIs+1); %includes space for AIF
ROIData.T1_s=nan(1,NROIs+1); %includes space for AIF
ROIData.FA_deg=nan(1,NROIs+1); %includes space for AIF
ROIData.S0=nan(acqPars.DCENFrames,NROIs+1); %includes space for AIF
ROIData.enhPct=nan(acqPars.DCENFrames,NROIs+1); %includes space for AIF
ROIData.conc_mM=nan(acqPars.DCENFrames,NROIs+1); %includes space for AIF
ROIData.concFit_mM=nan(acqPars.DCENFrames,NROIs); %includes space for AIF
ROIData.Patlak_vP=nan(1,NROIs);
ROIData.Patlak_PSperMin=nan(1,NROIs);
ROIData.PatlakMap_vP=nan(1,NROIs);
ROIData.PatlakMap_PSperMin=nan(1,NROIs);

%%Get ROI signals, FA and T1 
for iROI=1:NROIs+1 %(includes AIF)
    temp=measure4D(SI4D,[opts.DCEROIDir '/' maskNames{iROI} '.nii']); ROIData.SI(:,iROI)=temp.mean;
    temp=measure4D(T1Map_s,[opts.DCEROIDir '/' maskNames{iROI} '.nii']); ROIData.T1_s(1,iROI)=temp.median;
    temp=measure4D(FAMap_deg,[opts.DCEROIDir '/' maskNames{iROI} '.nii']); ROIData.FA_deg(1,iROI)=temp.median;

%     if iROI<=NROIs %get ROI PK parameters from parameter maps for comparison
%     temp=measure4D(Patlak_vP_map,[opts.DCEROIDir '/' maskNames{iROI} '.nii']); ROIData.PatlakMap_vP(:,iROI)=temp.median;
%     temp=measure4D(Patlak_PSperMin_map,[opts.DCEROIDir '/' maskNames{iROI} '.nii']); ROIData.PatlakMap_PSperMin(:,iROI)=temp.median;
%     end
end

%%Calculate ROI enhancements (includes AIF)
ROIData.enhPct=DCEFunc_Sig2Enh(ROIData.SI,1:opts.DCENFramesBase);

%%Calculate ROI concentrations (includes AIF)
ROIData.conc_mM=DCEFunc_Enh2Conc_SPGR(ROIData.enhPct,ROIData.T1_s,acqPars.TR_s,acqPars.TE_s,ROIData.FA_deg,opts.r1_permMperS,opts.r2s_permMperS);
ROIData.conc_mM(:,end)=ROIData.conc_mM(:,end)/(1-opts.Hct); %convert AIF voxel concentration to plasma concentration

%%Calculate ROI PK parameters (excludes AIF)
[PKP, ROIData.concFit_mM]=DCEFunc_fitModel(acqPars.tRes_s,ROIData.conc_mM(:,1:end-1),ROIData.conc_mM(:,end),'Patlak',struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));
ROIData.Patlak_vP=PKP.vP;
ROIData.Patlak_PSperMin=PKP.PS_perMin;

%%Plot data and results
figure(1), %signal intensity
set(gcf,'Units','centimeters','Position',[50,0,30,30])
for iROI=1:NROIs+1
    subplot(n,n,iROI)
    plot(ROIData.t_S,ROIData.SI(:,iROI),'b-o')
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.SI(:,iROI))-10 max(ROIData.SI(:,iROI))+10]);
    title([maskNames{iROI} ' (mean SI)'])
end

figure(2), %signal enhancement
set(gcf,'Units','centimeters','Position',[50,0,30,30])
for iROI=1:NROIs+1
    subplot(n,n,iROI)
    plot(ROIData.t_S,ROIData.enhPct(:,iROI),'b-o')
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.enhPct(:,iROI))-1 max(ROIData.enhPct(:,iROI))+1]);
    title([maskNames{iROI} ' (enhancement pct)'])
end

figure(3), %concentration and Patlak fit
set(gcf,'Units','centimeters','Position',[50,0,30,30])
for iROI=1:NROIs+1
    subplot(n,n,iROI)
    plot(ROIData.t_S,ROIData.conc_mM(:,iROI),'bo')
    hold on
    if iROI<=NROIs
        plot(ROIData.t_S,ROIData.concFit_mM(:,iROI),'b-') %plot fitted conc
    else
        plot(ROIData.t_S,ROIData.conc_mM(:,end),'b-') %as AIF not fitted, just connect values with line
    end
    hold on
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.conc_mM(:,iROI)) max(ROIData.conc_mM(:,iROI))]);
    title([maskNames{iROI} ' (conc and Patlak fit mM)'])
end

figure(4), %Patlak results
set(gcf,'Units','centimeters','Position',[55,0,30,30])
for iROI=1:NROIs
    subplot(n,n,iROI)
    title({[maskNames{iROI} ' (Patlak results)'];...
        ['PS (per min): ' num2str(ROIData.Patlak_PSperMin(1,iROI),'%.5f')];...
        ['vP: ' num2str(ROIData.Patlak_vP(1,iROI),'%.5f')];...
        ['FA (deg): ' num2str(ROIData.FA_deg(1,iROI),'%.1f')];...
        ['T1 (s): ' num2str(ROIData.T1_s(1,iROI),'%.2f')];...
        [''];...
%         ['PS (per min, from map): ' num2str(ROIData.PatlakMap_PSperMin(1,iROI),'%.5f')];...
%         ['vP (from map): ' num2str(ROIData.PatlakMap_vP(1,iROI),'%.5f')];...
        },'VerticalAlignment','top')
    axis off
end

%% Print figures and save data
saveas(1,[opts.DCEROIProcDir '/SI.jpg']); saveas(1,[opts.DCEROIProcDir '/SI'])
saveas(2,[opts.DCEROIProcDir '/enh.jpg']); saveas(2,[opts.DCEROIProcDir '/enh'])
saveas(3,[opts.DCEROIProcDir '/conc.jpg']); saveas(3,[opts.DCEROIProcDir '/conc'])
save([opts.DCEROIProcDir '/ROIData'],'ROIData');

end
