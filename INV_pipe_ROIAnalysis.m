function INV_pipe_ROIAnalysis(opts)
%note that AIF data is stored in the last entry of the arrays as plasma (Cp) values
close all;

if opts.overwrite==0 && exist([opts.DCEROIProcDir '/ROIData.mat'],'file'); return; end

%% make output directory and delete existing output files
mkdir(opts.DCEROIProcDir); delete([opts.DCEROIProcDir '/*.*']);

%% load 4D DCE, T1 data and acquisition parameters
SI4D=spm_read_vols(spm_vol([opts.DCENIIDir '/rDCE.nii']));
[T1Map_s,temp]=spm_read_vols(spm_vol([opts.DCENIIDir '/rT1.nii']));
[kMap,temp]=spm_read_vols(spm_vol([opts.DCENIIDir '/rk.nii']));
load([opts.DCENIIDir '/acqPars']);

%% load Patlak parameter maps (for comparison), if available
isSampleMaps = (exist([opts.DCENIIDir '/PatlakFast_vP.nii'],'file')==2) && (exist([opts.DCENIIDir '/PatlakFast_PSperMin.nii'],'file')==2);
if isSampleMaps
    Patlak_vP_map=spm_read_vols(spm_vol([opts.DCENIIDir '/PatlakFast_vP.nii']));
    Patlak_PSperMin_map=spm_read_vols(spm_vol([opts.DCENIIDir '/PatlakFast_PSperMin.nii']));
end

%% derive parameters
NROIs=size(opts.ROINames,2); %number of ROIs excluding AIF
NTimePoints=size(SI4D,1);
FAMap_deg=kMap * acqPars.FA_deg; %obtain FA map by scaling nominal flip angle by k
ROIData.t_S=((1:acqPars.DCENFrames)-0.5)*acqPars.tRes_s; %calculate time at centre of each acquisition relative to start of DCE - used only for plotting
maskNames=[opts.ROINames opts.AIFName];

%% initialise variables
ROIData.medianSI=nan(acqPars.DCENFrames,NROIs+1); %array of signals (time,ROI). includes space for AIF
ROIData.medianT1_s=nan(1,NROIs+1); %includes space for AIF
ROIData.medianFA_deg=nan(1,NROIs+1); %includes space for AIF
ROIData.meanSI=nan(acqPars.DCENFrames,NROIs+1); %array of signals (time,ROI). includes space for AIF
ROIData.meanT1_s=nan(1,NROIs+1); %includes space for AIF
ROIData.meanFA_deg=nan(1,NROIs+1); %includes space for AIF
ROIData.median_enhPct=nan(acqPars.DCENFrames,NROIs+1); %includes space for AIF
ROIData.median_conc_mM=nan(acqPars.DCENFrames,NROIs+1); %includes space for AIF
ROIData.mean_enhPct=nan(acqPars.DCENFrames,NROIs+1); %includes space for AIF
ROIData.mean_conc_mM=nan(acqPars.DCENFrames,NROIs+1); %includes space for AIF
ROIData.medianConcFit_mM=nan(acqPars.DCENFrames,NROIs); %includes space for AIF
ROIData.meanConcFit_mM=nan(acqPars.DCENFrames,NROIs); %includes space for AIF
ROIData.medianPatlak=[]; %Patlak results
ROIData.medianPatlakLinear=[]; %linear graphical Patlak results
ROIData.meanPatlak=[]; %Patlak results
ROIData.meanPatlakLinear=[]; %linear graphical Patlak results
ROIData.medianPatlakMap_PSperMin=nan(1,NROIs); %Patlak results, sampled from parameter maps
ROIData.medianPatlakMap_vP=nan(1,NROIs); %Patlak results, sampled from parameter maps
ROIData.meanPatlakMap_PSperMin=nan(1,NROIs); %Patlak results, sampled from parameter maps
ROIData.meanPatlakMap_vP=nan(1,NROIs); %Patlak results, sampled from parameter maps

%% loop through ROIs and determine signals, enhancements, concentrations etc.
for iROI=1:NROIs+1 %(includes AIF)
    
    if iROI==NROIs+1; DCEROIDir = opts.DCEVIFDir;
    else DCEROIDir = opts.DCEROIDir; end
    
    if ~exist([DCEROIDir '/' maskNames{iROI} '.nii'],'file'); %skip ROIs where mask doesn't exist
        disp(['Warning! ROI not found: ' DCEROIDir '/' maskNames{iROI} '.nii']);
        continue;
    end

    %% Get ROI signals, FA and T1
    temp=measure4D(SI4D,[DCEROIDir '/' maskNames{iROI} '.nii']); ROIData.medianSI(:,iROI)=temp.median; ROIData.meanSI(:,iROI)=temp.mean;
    temp=measure4D(T1Map_s,[DCEROIDir '/' maskNames{iROI} '.nii']); ROIData.medianT1_s(1,iROI)=temp.median; ROIData.meanT1_s(1,iROI)=temp.mean;
    temp=measure4D(FAMap_deg,[DCEROIDir '/' maskNames{iROI} '.nii']); ROIData.medianFA_deg(1,iROI)=temp.median; ROIData.meanFA_deg(1,iROI)=temp.mean;
    
    %% get a second set of Patlak parameters from the Patlak parameter maps for comparison
    if isSampleMaps
        if iROI<=NROIs 
            temp=measure4D(Patlak_vP_map,[DCEROIDir '/' maskNames{iROI} '.nii']); ROIData.medianPatlakMap_vP(1,iROI)=temp.median; ROIData.meanPatlakMap_vP(1,iROI)=temp.mean;
            temp=measure4D(Patlak_PSperMin_map,[DCEROIDir '/' maskNames{iROI} '.nii']); ROIData.medianPatlakMap_PSperMin(1,iROI)=temp.median; ROIData.meanPatlakMap_PSperMin(1,iROI)=temp.mean;
        end
    end
    
    %% Calculate ROI enhancements (includes AIF)
    ROIData.median_enhPct=DCEFunc_Sig2Enh(ROIData.medianSI,1:opts.DCENFramesBase);
    ROIData.mean_enhPct=DCEFunc_Sig2Enh(ROIData.meanSI,1:opts.DCENFramesBase);
    
    %% Calculate ROI concentrations (includes AIF)
    ROIData.median_conc_mM=DCEFunc_Enh2Conc_SPGR(ROIData.median_enhPct,ROIData.medianT1_s,acqPars.TR_s,acqPars.TE_s,ROIData.medianFA_deg,opts.r1_permMperS,opts.r2s_permMperS);
    ROIData.median_conc_mM(:,end)=ROIData.median_conc_mM(:,end)/(1-opts.Hct); %convert AIF voxel concentration to plasma concentration
end

%% loop through ROIs (excluding AIF) and fit Patlak model
for iROI=1:NROIs %(excludes AIF)
    if ~exist([opts.DCEROIDir '/' maskNames{iROI} '.nii'],'file'); continue; end  %skip ROIs where mask doesn't exist
    
    %% Calculate ROI PK parameters (excludes AIF)
    [ROIData.medianPatlak, ROIData.medianConcFit_mM]=DCEFunc_fitModel(acqPars.tRes_s,ROIData.median_conc_mM(:,1:end-1),ROIData.median_conc_mM(:,end),'PatlakFast',struct('NIgnore',opts.NIgnore));
    [ROIData.meanPatlak, ROIData.meanConcFit_mM]=DCEFunc_fitModel(acqPars.tRes_s,ROIData.mean_conc_mM(:,1:end-1),ROIData.mean_conc_mM(:,end),'PatlakFast',struct('NIgnore',opts.NIgnore));
    [ROIData.medianPatlakLinear, ROIData.medianConcFitLinear_mM]=DCEFunc_fitModel(acqPars.tRes_s,ROIData.median_conc_mM(:,1:end-1),ROIData.median_conc_mM(:,end),'PatlakLinear',struct('NIgnore',opts.NIgnore));
    [ROIData.meanPatlakLinear, ROIData.meanConcFitLinear_mM]=DCEFunc_fitModel(acqPars.tRes_s,ROIData.mean_conc_mM(:,1:end-1),ROIData.mean_conc_mM(:,end),'PatlakLinear',struct('NIgnore',opts.NIgnore));
    
    %% Plot data and results (using MEDIANS at the moment)
    figure(iROI)
    set(gcf,'Units','centimeters','Position',[50,0,30,30],'PaperPositionMode','auto','DefaultTextInterpreter', 'none')
    
    subplot(4,2,1) %signal intensity
    plot(ROIData.t_S,ROIData.medianSI(:,iROI),'b.:')
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.medianSI(:,iROI))-10 max(ROIData.medianSI(:,iROI))+10]);
    title([maskNames{iROI} ':  SI'])
    xlabel('time (s)');
    
    subplot(4,2,2) %enhancement
    plot(ROIData.t_S,ROIData.median_enhPct(:,iROI),'b.:')
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.median_enhPct(:,iROI))-1 max(ROIData.median_enhPct(:,iROI))+1]);
    title([maskNames{iROI} ': enhancement (%)'])
    xlabel('time (s)');
    line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
    
    subplot(4,2,3) %concentration and Patlak fit
    plot(ROIData.t_S,ROIData.median_conc_mM(:,iROI),'b.:')
    hold on
    plot(ROIData.t_S,ROIData.medianConcFit_mM(:,iROI),'k-') %plot fitted conc
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.median_conc_mM(:,iROI))-2e-3 max(ROIData.median_conc_mM(:,iROI))+2e-3]);
    title([maskNames{iROI} ': [GBCA] with Patlak model fit (mM)'])
    xlabel('time (s)');
    line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
    
    subplot(4,2,4) %VIF signal intensity
    plot(ROIData.t_S,ROIData.medianSI(:,end),'b.:')
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.medianSI(:,end))-100 max(ROIData.medianSI(:,end))+200]);
    title([maskNames{end} ': SI'])
    xlabel('time (s)');
    
    subplot(4,2,5) %VIF enhancement
    plot(ROIData.t_S,ROIData.median_enhPct(:,end),'b.:')
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.median_enhPct(:,end))-20 max(ROIData.median_enhPct(:,end))+50]);
    title([maskNames{end} ': enhancement (%)'])
    xlabel('time (s)');
    line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
    
    subplot(4,2,6) %VIF concentration
    plot(ROIData.t_S,ROIData.median_conc_mM(:,end),'b.:') %as AIF not fitted, just connect values with line
    hold on
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.median_conc_mM(:,end))-0.1 max(ROIData.median_conc_mM(:,end))+0.2]);
    title([maskNames{end} ': [plasma GBCA] (mM)'])
    xlabel('time (s)');
    line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
    
    subplot(4,2,8) %Patlak results
    title({...
        [strrep(opts.subjectCode,'_','-')];...
        ['ROI: ' maskNames{iROI}];...
        ['Patlak / Patlak plot results:'];...
        ['PS (10^{-4} per min): ' num2str(1e4*ROIData.medianPatlak.PS_perMin(1,iROI),'%.5f')...
        ' / ' num2str(1e4*ROIData.medianPatlakLinear.PS_perMin(1,iROI),'%.5f')];...
        ['vP: ' num2str(ROIData.medianPatlak.vP(1,iROI),'%.5f')...
        ' / ' num2str(ROIData.medianPatlakLinear.vP(1,iROI),'%.5f')];...
        ['FA (deg): ' num2str(ROIData.medianFA_deg(1,iROI),'%.1f')];...
        ['T1 (s): ' num2str(ROIData.medianT1_s(1,iROI),'%.2f')];...
        ['FA (VIF, deg): ' num2str(ROIData.medianFA_deg(1,end),'%.1f')];...
        ['T1 (VIF, s): ' num2str(ROIData.medianT1_s(1,end),'%.2f')];...
        [''];...
        ['PS (10^{-4} per min, from map): ' num2str(1e4*ROIData.medianPatlakMap_PSperMin(1,iROI),'%.5f')];...
        ['vP (from map): ' num2str(ROIData.medianPatlakMap_vP(1,iROI),'%.5f')];...
        },'VerticalAlignment','top','HorizontalAlignment','left','Position',[0 1])
    axis off
    
    subplot(4,2,7) %Linear graphical Patlak fit
    plot(ROIData.medianPatlakLinear.PatlakX(1:end,iROI),ROIData.medianPatlakLinear.PatlakY(1:end,iROI),'b.')
    hold on
    plot(ROIData.medianPatlakLinear.PatlakX(opts.NIgnore+1:end,iROI),ROIData.medianPatlakLinear.PatlakYFit(opts.NIgnore+1:end,iROI),'b-')
    xlim([min(ROIData.medianPatlakLinear.PatlakX(opts.NIgnore+1:end,iROI)) max(ROIData.medianPatlakLinear.PatlakX(opts.NIgnore+1:end,iROI))]); ylim([min(ROIData.medianPatlakLinear.PatlakY(opts.NIgnore+1:end,iROI)) max(ROIData.medianPatlakLinear.PatlakY(opts.NIgnore+1:end,iROI))]);
    ylim([0 max(ROIData.medianPatlakLinear.PatlakY(opts.NIgnore+1:end,iROI))]);
    title([maskNames{iROI} ': Patlak plot fit'])
    xlabel('X (s)'); ylabel('Y');
    
    %save figure
    saveas(iROI,[opts.DCEROIProcDir '/ROI_results_' maskNames{iROI} '.jpg']);
end

%% Save data
save([opts.DCEROIProcDir '/ROIData'],'ROIData');

end
