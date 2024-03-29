function INV_pipe_ROIAnalysis(opts)
%note that AIF data is stored in the last entry of the arrays as plasma (Cp) values
close all;

if opts.overwrite==0 && exist([opts.DCEROIProcDir '/ROIData.mat'],'file'); return; end

if ~isfield(opts,'ROIPatlakFastRegMode'); opts.ROIPatlakFastRegMode='linear'; end %default to linear regression

if ~isfield(opts,'DCEFramesBaseIdx'); opts.DCEFramesBaseIdx=1:opts.DCENFramesBase; end %if indices for baseline are not specified, us all points from 1 to opts.DCENFramesBase


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
    Patlak_vB_map=spm_read_vols(spm_vol([opts.DCENIIDir '/PatlakFast_vB.nii']));
    Patlak_k_perMin_map=spm_read_vols(spm_vol([opts.DCENIIDir '/PatlakFast_k_perMin.nii']));
end

%% derive parameters
NROIs=size(opts.ROINames,2); %number of ROIs excluding AIF
NTimePoints=size(SI4D,4);
FAMap_deg=kMap * acqPars.FA_deg; %obtain FA map by scaling nominal flip angle by k
ROIData.t_S=((1:acqPars.DCENFrames)-0.5)*acqPars.tRes_s; %calculate time at centre of each acquisition relative to start of DCE - used only for plotting
maskNames=[opts.ROINames opts.AIFName];

if ~isfield(opts,'driftMedian')
    opts.driftMedian=zeros(1,NROIs+1);
else
    opts.driftMedian=[opts.driftMedian 0]; %entry for AIF (no correction)
end
if ~isfield(opts,'driftMean')
    opts.driftMean=zeros(1,NROIs+1);
else
    opts.driftMean=[opts.driftMean 0]; %entry for AIF (no correction)
end

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
ROIData.medianPatlakMap_vB=nan(1,NROIs); %Patlak results, sampled from parameter maps
ROIData.medianPatlakMap_k_perMin=nan(1,NROIs); %Patlak results, sampled from parameter maps
ROIData.meanPatlakMap_PSperMin=nan(1,NROIs); %Patlak results, sampled from parameter maps
ROIData.meanPatlakMap_vP=nan(1,NROIs); %Patlak results, sampled from parameter maps
ROIData.meanPatlakMap_vB=nan(1,NROIs); %Patlak results, sampled from parameter maps
ROIData.meanPatlakMap_k_perMin=nan(1,NROIs); %Patlak results, sampled from parameter maps

masks=cell(1,NROIs);

%% loop through ROIs and determine signals, enhancements, concentrations etc.
for iROI=1:NROIs+1 %(includes AIF)
    
    if iROI==NROIs+1; DCEROIDir = opts.DCEAIFDir;
    else DCEROIDir = opts.DCEROIDir; end
    
    if ~exist([DCEROIDir '/' maskNames{iROI} '.nii'],'file') %skip ROIs where mask doesn't exist
        disp(['Warning! ROI not found: ' DCEROIDir '/' maskNames{iROI} '.nii']);
        continue;
    else
        [masks{iROI},temp] = spm_read_vols(spm_vol([DCEROIDir '/' maskNames{iROI} '.nii']));
    end
    
    %% Get ROI signals, FA and T1
    temp=measure4D(SI4D,masks{iROI}); ROIData.medianSI(:,iROI)=temp.median; ROIData.meanSI(:,iROI)=temp.mean;
    temp=measure4D(T1Map_s,masks{iROI}); ROIData.medianT1_s(1,iROI)=temp.median; ROIData.meanT1_s(1,iROI)=temp.mean;
    temp=measure4D(FAMap_deg,masks{iROI}); ROIData.medianFA_deg(1,iROI)=temp.median; ROIData.meanFA_deg(1,iROI)=temp.mean;
    
    %% get a second set of Patlak parameters from the Patlak parameter maps for comparison
    if isSampleMaps
        if iROI<=NROIs
            temp=measure4D(Patlak_vP_map,masks{iROI});
            ROIData.medianPatlakMap_vP(1,iROI)=temp.median;
            ROIData.meanPatlakMap_vP(1,iROI)=temp.mean;
            
            temp=measure4D(Patlak_PSperMin_map,masks{iROI});
            ROIData.medianPatlakMap_PSperMin(1,iROI)=temp.median;
            ROIData.meanPatlakMap_PSperMin(1,iROI)=temp.mean;
            
            temp=measure4D(Patlak_k_perMin_map,masks{iROI});
            ROIData.medianPatlakMap_k_perMin(1,iROI)=temp.median;
            ROIData.meanPatlakMap_k_perMin(1,iROI)=temp.mean;
            
            temp=measure4D(Patlak_vB_map,masks{iROI});
            ROIData.medianPatlakMap_vB(1,iROI)=temp.median;
            ROIData.meanPatlakMap_vB(1,iROI)=temp.mean;
        end
    end
    
end

%% Apply drift correction to SI
ROIData.medianSI = ROIData.medianSI - repmat(ROIData.medianSI(1,:),[NTimePoints,1]) .* repmat(opts.driftMedian/100,[NTimePoints,1]) .* (repmat(ROIData.t_S.',[1,NROIs+1]) - ROIData.t_S(1))/60;
ROIData.meanSI = ROIData.meanSI - repmat(ROIData.meanSI(1,:),[NTimePoints,1]) .* repmat(opts.driftMean/100,[NTimePoints,1]) .* (repmat(ROIData.t_S.',[1,NROIs+1]) - ROIData.t_S(1))/60;

%% Calculate ROI enhancements (includes AIF)
ROIData.median_enhPct=DCEFunc_Sig2Enh(ROIData.medianSI,opts.DCEFramesBaseIdx);
ROIData.mean_enhPct=DCEFunc_Sig2Enh(ROIData.meanSI,opts.DCEFramesBaseIdx);

%% Calculate ROI concentrations (includes AIF)
ROIData.median_conc_mM=DCEFunc_Enh2Conc_SPGR(ROIData.median_enhPct,ROIData.medianT1_s,acqPars.TR_s,acqPars.TE_s,ROIData.medianFA_deg,opts.r1_permMperS,opts.r2s_permMperS,opts.Enh2ConcMode);
ROIData.median_conc_mM(:,end)=ROIData.median_conc_mM(:,end)/(1-opts.Hct); %convert AIF voxel concentration to plasma concentration
ROIData.mean_conc_mM=DCEFunc_Enh2Conc_SPGR(ROIData.mean_enhPct,ROIData.meanT1_s,acqPars.TR_s,acqPars.TE_s,ROIData.meanFA_deg,opts.r1_permMperS,opts.r2s_permMperS,opts.Enh2ConcMode);
ROIData.mean_conc_mM(:,end)=ROIData.mean_conc_mM(:,end)/(1-opts.Hct); %convert AIF voxel concentration to plasma concentration

%% For Patlak plots increase NIgnore as necessary to exclude datapoints where there is little contrast in the blood (prevents noise blowing up)
NIgnorePatlakPlot = max([opts.NIgnore sum(ROIData.mean_conc_mM(:,end) < 0.2)]);

%% Calculate ROI PK parameters (excludes AIF)
[ROIData.medianPatlak, ROIData.medianConcFit_mM]=DCEFunc_fitModel(acqPars.tRes_s,ROIData.median_conc_mM(:,1:end-1),ROIData.median_conc_mM(:,end),'PatlakFast',struct('NIgnore',opts.NIgnore,'PatlakFastRegMode',opts.ROIPatlakFastRegMode));
[ROIData.meanPatlak, ROIData.meanConcFit_mM]=DCEFunc_fitModel(acqPars.tRes_s,ROIData.mean_conc_mM(:,1:end-1),ROIData.mean_conc_mM(:,end),'PatlakFast',struct('NIgnore',opts.NIgnore,'PatlakFastRegMode',opts.ROIPatlakFastRegMode));
[ROIData.medianPatlakLinear, ROIData.medianConcFitLinear_mM]=DCEFunc_fitModel(acqPars.tRes_s,ROIData.median_conc_mM(:,1:end-1),ROIData.median_conc_mM(:,end),'PatlakLinear',struct('NIgnore',NIgnorePatlakPlot,'PatlakFastRegMode',opts.ROIPatlakFastRegMode));
[ROIData.meanPatlakLinear, ROIData.meanConcFitLinear_mM]=DCEFunc_fitModel(acqPars.tRes_s,ROIData.mean_conc_mM(:,1:end-1),ROIData.mean_conc_mM(:,end),'PatlakLinear',struct('NIgnore',NIgnorePatlakPlot,'PatlakFastRegMode',opts.ROIPatlakFastRegMode));
%calculate derived parameters vB and k...
ROIData.medianPatlak.vB=ROIData.medianPatlak.vP/(1-opts.Hct);
ROIData.medianPatlak.k_perMin=ROIData.medianPatlak.PS_perMin./ROIData.medianPatlak.vB;
ROIData.meanPatlak.vB=ROIData.meanPatlak.vP/(1-opts.Hct);
ROIData.meanPatlak.k_perMin=ROIData.meanPatlak.PS_perMin./ROIData.meanPatlak.vB;
ROIData.medianPatlakLinear.vB=ROIData.medianPatlakLinear.vP/(1-opts.Hct);
ROIData.medianPatlakLinear.k_perMin=ROIData.medianPatlakLinear.PS_perMin./ROIData.medianPatlakLinear.vB;
ROIData.meanPatlakLinear.vB=ROIData.meanPatlakLinear.vP/(1-opts.Hct);
ROIData.meanPatlakLinear.k_perMin=ROIData.meanPatlakLinear.PS_perMin./ROIData.meanPatlakLinear.vB;

%% Calculate alternative ROI PK parameters using SXL fit
[SXLData.mean, SXLData.mean_enhancementPct_fit]=DCEFunc_fitPatlak_waterEx...
    (acqPars.tRes_s,ROIData.mean_enhPct(:,1:end-1),ROIData.mean_conc_mM(:,end),opts.Hct,ROIData.meanT1_s(:,1:end-1),ROIData.meanT1_s(end),...
    acqPars.TR_s,acqPars.TE_s,ROIData.meanFA_deg,opts.r1_permMperS,opts.r2s_permMperS,struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));
[SXLData.median, SXLData.median_enhancementPct_fit]=DCEFunc_fitPatlak_waterEx...
    (acqPars.tRes_s,ROIData.median_enhPct(:,1:end-1),ROIData.median_conc_mM(:,end),opts.Hct,ROIData.medianT1_s(:,1:end-1),ROIData.medianT1_s(end),...
    acqPars.TR_s,acqPars.TE_s,ROIData.medianFA_deg,opts.r1_permMperS,opts.r2s_permMperS,struct('NIgnore',opts.NIgnore,'init_vP',opts.init_vP,'init_PS_perMin',opts.init_PS_perMin));

%% loop through ROIs (excluding AIF) and plot data and results (using MEANS and MEDIANS)
for iROI=1:NROIs %(excludes AIF)
    if ~exist([opts.DCEROIDir '/' maskNames{iROI} '.nii'],'file'); continue; end  %skip ROIs where mask doesn't exist
    if isempty(find(masks{iROI}==1)); continue; end %if there are no voxels in the mask, don't plot
    
    meanMedian={'mean' 'median'};
    for iPlot=1:2 %loop through this twice to plot mean and median results
        figure(1)
        set(gcf,'Units','centimeters','Position',[0,0,20,30],'PaperPositionMode','auto','DefaultTextInterpreter', 'none')
        
        subplot(4,2,1) %signal intensity
        plot(ROIData.t_S,ROIData.([meanMedian{iPlot} 'SI'])(:,iROI),'b.:')
        xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.([meanMedian{iPlot} 'SI'])(:,iROI))-10 max(ROIData.([meanMedian{iPlot} 'SI'])(:,iROI))+10]);
        title([opts.ROILabels{iROI} ':  SI'])
        xlabel('time (s)');
        
        subplot(4,2,2) %enhancement
        plot(ROIData.t_S,ROIData.([meanMedian{iPlot} '_enhPct'])(:,iROI),'b.:'); hold on;
        plot(ROIData.t_S,SXLData.([meanMedian{iPlot} '_enhancementPct_fit'])(:,iROI),'g');
        xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.([meanMedian{iPlot} '_enhPct'])(:,iROI))-1 max(ROIData.([meanMedian{iPlot} '_enhPct'])(:,iROI))+1]);
        title([opts.ROILabels{iROI} ': enhancement + SXL fit (%)'])
        xlabel('time (s)');
        line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
        
        subplot(4,2,3) %concentration and Patlak fit
        plot(ROIData.t_S,ROIData.([meanMedian{iPlot} '_conc_mM'])(:,iROI),'b.:')
        hold on
        plot(ROIData.t_S,ROIData.([meanMedian{iPlot} 'ConcFit_mM'])(:,iROI),'k-') %plot fitted conc
        plot(ROIData.t_S,SXLData.(meanMedian{iPlot}).Ct_SXL_mM(:,iROI),'g')
        xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.([meanMedian{iPlot} '_conc_mM'])(:,iROI))-2e-3 max(ROIData.([meanMedian{iPlot} '_conc_mM'])(:,iROI))+2e-3]);
        title({[maskNames{iROI} ': [GBCA] with Patlak model fit (mM)']; ['(green SXL fit conc)']})
        xlabel('time (s)');
        line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
        
        subplot(4,2,4) %VIF signal intensity
        plot(ROIData.t_S,ROIData.([meanMedian{iPlot} 'SI'])(:,end),'b.:')
        xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.([meanMedian{iPlot} 'SI'])(:,end))-100 max(ROIData.([meanMedian{iPlot} 'SI'])(:,end))+200]);
        title([maskNames{end} ': SI'])
        xlabel('time (s)');
        
        subplot(4,2,5) %VIF enhancement
        plot(ROIData.t_S,ROIData.([meanMedian{iPlot} '_enhPct'])(:,end),'b.:')
        xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.([meanMedian{iPlot} '_enhPct'])(:,end))-20 max(ROIData.([meanMedian{iPlot} '_enhPct'])(:,end))+50]);
        title([maskNames{end} ': enhancement (%)'])
        xlabel('time (s)');
        line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
        
        subplot(4,2,6) %VIF concentration
        plot(ROIData.t_S,ROIData.([meanMedian{iPlot} '_conc_mM'])(:,end),'b.:') %as AIF not fitted, just connect values with line
        hold on
        xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.([meanMedian{iPlot} '_conc_mM'])(:,end))-0.1 max(ROIData.([meanMedian{iPlot} '_conc_mM'])(:,end))+0.2]);
        title([maskNames{end} ': [plasma GBCA] (mM)'])
        xlabel('time (s)');
        line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
        
        subplot(4,2,8) %Patlak results
        title({...
            [strrep(opts.subjectCode,'_','-') ' (' meanMedian{iPlot} ')'];...
            ['ROI: ' opts.ROILabels{iROI}];...
            ['Patlak / Patlak plot results:'];...
            ['PS (10^{-4} per min): ' num2str(1e4*ROIData.([meanMedian{iPlot} 'Patlak']).PS_perMin(1,iROI),'%.5f')...
            ' / ' num2str(1e4*ROIData.([meanMedian{iPlot} 'PatlakLinear']).PS_perMin(1,iROI),'%.5f')];...
            ['vP: ' num2str(ROIData.([meanMedian{iPlot} 'Patlak']).vP(1,iROI),'%.5f')...
            ' / ' num2str(ROIData.([meanMedian{iPlot} 'PatlakLinear']).vP(1,iROI),'%.5f')];...
            ['FA (deg): ' num2str(ROIData.([meanMedian{iPlot} 'FA_deg'])(1,iROI),'%.1f')];...
            ['PS (10^{-4} per min (SXL fit): ' num2str(1e4*SXLData.([meanMedian{iPlot}]).PS_perMin(1,iROI),'%.5f')];...
            ['vP (SXL fit); ' num2str(SXLData.([meanMedian{iPlot}]).vP(1,iROI),'%.5f')];...
            ['T1 (s): ' num2str(ROIData.([meanMedian{iPlot} 'T1_s'])(1,iROI),'%.2f')];...
            ['FA (VIF, deg): ' num2str(ROIData.([meanMedian{iPlot} 'FA_deg'])(1,end),'%.1f')];...
            ['T1 (VIF, s): ' num2str(ROIData.([meanMedian{iPlot} 'T1_s'])(1,end),'%.2f')];...
            ['Hct: ' num2str(opts.Hct)];...
            [''];...
            ['PS (10^{-4} per min, from map): ' num2str(1e4*ROIData.([meanMedian{iPlot} 'PatlakMap_PSperMin'])(1,iROI),'%.5f')];...
            ['vP (from map): ' num2str(ROIData.([meanMedian{iPlot} 'PatlakMap_vP'])(1,iROI),'%.5f')];...
            },'VerticalAlignment','top','HorizontalAlignment','left','Position',[0 1])
        axis off
        
        subplot(4,2,7) %Linear graphical Patlak fit
        plot(ROIData.([meanMedian{iPlot} 'PatlakLinear']).PatlakX(NIgnorePatlakPlot+1:end,iROI),ROIData.([meanMedian{iPlot} 'PatlakLinear']).PatlakY(NIgnorePatlakPlot+1:end,iROI),'b.')
        hold on
        plot(ROIData.([meanMedian{iPlot} 'PatlakLinear']).PatlakX(NIgnorePatlakPlot+1:end,iROI),ROIData.([meanMedian{iPlot} 'PatlakLinear']).PatlakYFit(NIgnorePatlakPlot+1:end,iROI),'b-')
        %xlim([min(ROIData.medianPatlakLinear.PatlakX(opts.NIgnore+1:end,iROI)) max(ROIData.medianPatlakLinear.PatlakX(opts.NIgnore+1:end,iROI))]); ylim([min(ROIData.medianPatlakLinear.PatlakY(opts.NIgnore+1:end,iROI)) max(ROIData.medianPatlakLinear.PatlakY(opts.NIgnore+1:end,iROI))]);
        %ylim([0 max(ROIData.medianPatlakLinear.PatlakY(opts.NIgnore+1:end,iROI))]);
        title([opts.ROILabels{iROI} ': Patlak plot fit'])
        xlabel('X (s)'); ylabel('Y');
        
        %save figure
        if isfield(opts,'visitNo'); subject_visitNo_str=[opts.subjectCode '_' num2str(opts.visitNo)]; else; subject_visitNo_str=[opts.subjectCode]; end
        saveas(1,[opts.DCEROIProcDir '/ROI_results_' maskNames{iROI} '_' subject_visitNo_str '_' meanMedian{iPlot} '.jpg']);
        saveas(1,[opts.DCEROIProcDir '/ROI_results_' maskNames{iROI} '_' subject_visitNo_str '_' meanMedian{iPlot} '.fig']);
        
        close(1);
    end
end

%% Save data
save([opts.DCEROIProcDir '/ROIData'],'ROIData');
save([opts.DCEROIProcDir '/opts'],'opts');
save([opts.DCEROIProcDir '/SXLData'],'SXLData');

end
