function INV_pipe_DCEQA_ROIAnalysis(opts)

close all;

load([opts.DCENIIDir '/acqPars']);

%% make output directory delete existing output files
mkdir(opts.DCEROIProcDir); delete([opts.DCEROIProcDir '/*.*']);

%% load 4D DCE and other data
SI4D=spm_read_vols(spm_vol([opts.DCENIIDir '/rDCE.nii']));
load([opts.DCENIIDir '/acqPars']);

%% derive parameters
NROIs=size(opts.ROINames,2);
NTimePoints=size(SI4D,1);
ROIData.t_S=((1:acqPars.DCENFrames)-0.5)*acqPars.tRes_s; %calculate time at centre of each acquisition relative to start of DCE - used only for plotting
maskNames=[opts.ROINames];


%% initialise variables
ROIData.signal=nan(acqPars.DCENFrames,NROIs);
ROIData.slope_perS=nan(1,NROIs);
ROIData.intercept=nan(1,NROIs);
ROIData.slope_PctPerS=nan(1,NROIs);
ROIData.changePct=nan(1,NROIs);
ROIData.signalFit=nan(acqPars.DCENFrames,NROIs);

%%get mean ROI signals
for iROI=1:NROIs
    temp=measure4D(SI4D,[opts.DCEROIDir '/' maskNames{iROI} '.nii']);
    ROIData.signal(:,iROI)=temp.mean;
end

%% fit all signals
lineFitObject=DCEFunc_fitLine(acqPars.tRes_s,ROIData.signal(:,:));
ROIData.slope_perS(1,:)=lineFitObject.slope_perS;
ROIData.slope_pctPerS(1,:)=lineFitObject.slope_pctPerS;
ROIData.intercept(1,:)=lineFitObject.intercept;
ROIData.changePct(1,:)=lineFitObject.changePct;
ROIData.signalFit(:,:)=lineFitObject.signalFit;

%%Plot data and results
for iROI=1:NROIs
    figure(iROI)
    set(gcf,'Units','centimeters','Position',[50,0,30,30],'PaperPositionMode','auto')
    
    subplot(4,2,1) %signal intensity
    plot(ROIData.t_S,ROIData.SI(:,iROI),'b.:')
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.SI(:,iROI))-10 max(ROIData.SI(:,iROI))+10]);
    title([maskNames{iROI} ': mean SI'])
    xlabel('time (s)');
    
    subplot(4,2,2) %enhancement
    plot(ROIData.t_S,ROIData.enhPct(:,iROI),'b.:')
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.enhPct(:,iROI))-1 max(ROIData.enhPct(:,iROI))+1]);
    title([maskNames{iROI} ': enhancement (%)'])
    xlabel('time (s)');
    line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
    
    
    subplot(4,2,3) %concentration and Patlak fit
    plot(ROIData.t_S,ROIData.conc_mM(:,iROI),'b.:')
    hold on
    plot(ROIData.t_S,ROIData.concFit_mM(:,iROI),'k-') %plot fitted conc
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.conc_mM(:,iROI))-2e-3 max(ROIData.conc_mM(:,iROI))+2e-3]);
    title([maskNames{iROI} ': [GBCA] with Patlak model fit (mM)'])
    xlabel('time (s)');
    line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
    
    subplot(4,2,4) %VIF signal intensity
    plot(ROIData.t_S,ROIData.SI(:,end),'b.:')
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.SI(:,end))-100 max(ROIData.SI(:,end))+200]);
    title([maskNames{end} ': mean SI'])
    xlabel('time (s)');
    
    subplot(4,2,5) %VIF enhancement
    plot(ROIData.t_S,ROIData.enhPct(:,end),'b.:')
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.enhPct(:,end))-20 max(ROIData.enhPct(:,end))+50]);
    title([maskNames{end} ': enhancement (%)'])
    xlabel('time (s)');
    line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
    
    subplot(4,2,6) %VIF concentration
    plot(ROIData.t_S,ROIData.conc_mM(:,end),'b.:') %as AIF not fitted, just connect values with line
    hold on
    xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.conc_mM(:,end))-0.1 max(ROIData.conc_mM(:,end))+0.2]);
    title([maskNames{end} ': [plasma GBCA] (mM)'])
    xlabel('time (s)');
    line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
    
    subplot(4,2,8) %Patlak results
    title({...
        [strrep(opts.subjectCode,'_','-')];...
        ['ROI: ' maskNames{iROI}];...
        ['Patlak / Linear Patlak results:'];...
        ['PS (10^{-4} per min): ' num2str(1e4*ROIData.Patlak.PS_perMin(1,iROI),'%.5f')...
        ' / ' num2str(1e4*ROIData.PatlakLinear.PS_perMin(1,iROI),'%.5f')];...
        ['vP: ' num2str(ROIData.Patlak.vP(1,iROI),'%.5f')...
        ' / ' num2str(ROIData.PatlakLinear.vP(1,iROI),'%.5f')];...
        ['FA (deg): ' num2str(ROIData.FA_deg(1,iROI),'%.1f')];...
        ['T1 (s): ' num2str(ROIData.T1_s(1,iROI),'%.2f')];...
        ['FA (VIF, deg): ' num2str(ROIData.FA_deg(1,end),'%.1f')];...
        ['T1 (VIF, s): ' num2str(ROIData.T1_s(1,end),'%.2f')];...
        [''];...
        ['PS (10^{-4} per min, from map): ' num2str(1e4*ROIData.PatlakMap_PSperMin(1,iROI),'%.5f')];...
        ['vP (from map): ' num2str(ROIData.PatlakMap_vP(1,iROI),'%.5f')];...
        },'VerticalAlignment','top','HorizontalAlignment','left','Position',[0 1])
    axis off
    
    subplot(4,2,7) %Linear Patlak fit
    plot(ROIData.PatlakLinear.PatlakX(1:end,iROI),ROIData.PatlakLinear.PatlakY(1:end,iROI),'b.')
    hold on
    plot(ROIData.PatlakLinear.PatlakX(opts.NIgnore+1:end,iROI),ROIData.PatlakLinear.PatlakYFit(opts.NIgnore+1:end,iROI),'b-')
    xlim([min(ROIData.PatlakLinear.PatlakX(opts.NIgnore+1:end,iROI)) max(ROIData.PatlakLinear.PatlakX(opts.NIgnore+1:end,iROI))]); ylim([min(ROIData.PatlakLinear.PatlakY(opts.NIgnore+1:end,iROI)) max(ROIData.PatlakLinear.PatlakY(opts.NIgnore+1:end,iROI))]);
    ylim([0 max(ROIData.PatlakLinear.PatlakY(opts.NIgnore+1:end,iROI))]);
    title([maskNames{iROI} ': linearised Patlak model fit'])
    xlabel('X (s)'); ylabel('Y');
end

%% Print figures and save data
for iROI=1:NROIs; saveas(iROI,[opts.DCEROIProcDir '/ROI_results_' maskNames{iROI} '.jpg']); end
save([opts.DCEROIProcDir '/ROIData'],'ROIData');

end
