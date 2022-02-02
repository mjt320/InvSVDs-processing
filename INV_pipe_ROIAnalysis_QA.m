function INV_pipe_ROIAnalysis_QA(opts)
close all;

if opts.overwrite==0 && exist([opts.DCEROIProcDir '/ROIData.mat'],'file'); return; end

if ~isfield(opts,'DCEFramesBaseIdx'); opts.DCEFramesBaseIdx=1:opts.DCENFramesBase; end %if indices for baseline are not specified, us all points from 1 to opts.DCENFramesBase

%% make output directory and delete existing output files
mkdir(opts.DCEROIProcDir); delete([opts.DCEROIProcDir '/*.*']);

%% load 4D DCE, T1 data and acquisition parameters
SI4D=spm_read_vols(spm_vol([opts.DCENIIDir '/rDCE.nii']));
load([opts.DCENIIDir '/acqPars']);

%% derive parameters
NROIs=size(opts.ROINames,2); %number of ROIs excluding AIF
NTimePoints=size(SI4D,1);
ROIData.t_S=((1:acqPars.DCENFrames)-0.5)*acqPars.tRes_s; %calculate time at centre of each acquisition relative to start of DCE - used only for plotting
maskNames=[opts.ROINames];

%% initialise variables
ROIData.medianSI=nan(acqPars.DCENFrames,NROIs); %array of signals (time,ROI)
ROIData.meanSI=nan(acqPars.DCENFrames,NROIs); %array of signals (time,ROI)
ROIData.median_enhPct=nan(acqPars.DCENFrames,NROIs);
ROIData.mean_enhPct=nan(acqPars.DCENFrames,NROIs);
ROIData.median_fit_enhPct=nan(acqPars.DCENFrames,NROIs);
ROIData.mean_fit_enhPct=nan(acqPars.DCENFrames,NROIs);


ROIData.medianEnhSlope=nan(1,NROIs);
ROIData.meanEnhSlope=nan(1,NROIs);
ROIData.medianEnhInt=nan(1,NROIs);
ROIData.meanEnhInt=nan(1,NROIs);

masks=cell(1,NROIs);

%% loop through ROIs and determine signals, enhancements, concentrations etc.
for iROI=1:NROIs
    
    DCEROIDir = opts.DCEROIDir;
    
    if ~exist([DCEROIDir '/' maskNames{iROI} '.nii'],'file') %skip ROIs where mask doesn't exist
        disp(['Warning! ROI not found: ' DCEROIDir '/' maskNames{iROI} '.nii']);
        continue;
    else
        [masks{iROI},temp] = spm_read_vols(spm_vol([DCEROIDir '/' maskNames{iROI} '.nii']));
    end
    
    %% Get ROI signals
    temp=measure4D(SI4D,masks{iROI}); ROIData.medianSI(:,iROI)=temp.median; ROIData.meanSI(:,iROI)=temp.mean;
    
    %% Calculate ROI enhancements
    ROIData.median_enhPct=DCEFunc_Sig2Enh(ROIData.medianSI,opts.DCEFramesBaseIdx);
    ROIData.mean_enhPct=DCEFunc_Sig2Enh(ROIData.meanSI,opts.DCEFramesBaseIdx);
    
    %% Calculate Slopes
    temp = polyfit(ROIData.t_S,ROIData.median_enhPct(:,iROI).',1);
    ROIData.medianEnhInt(1,iROI)=temp(2);
    ROIData.medianEnhSlope(1,iROI)=temp(1);
    ROIData.median_fit_enhPct = polyval(temp,ROIData.t_S);
    temp = polyfit(ROIData.t_S,ROIData.mean_enhPct(:,iROI).',1);
    ROIData.meanEnhInt(1,iROI)=temp(2);
    ROIData.meanEnhSlope(1,iROI)=temp(1);
    ROIData.mean_fit_enhPct = polyval(temp,ROIData.t_S);
    
end


%% loop through ROIs and plot data and results (using MEANS and MEDIANS)
for iROI=1:NROIs
    if ~exist([opts.DCEROIDir '/' maskNames{iROI} '.nii'],'file'); continue; end  %skip ROIs where mask doesn't exist
    if isempty(find(masks{iROI}==1)); continue; end %if there are no voxels in the mask, don't plot
    
    meanMedian={'mean' 'median'};
    for iPlot=1:2 %loop through this twice to plot mean and median results
        figure(1)
        set(gcf,'Units','centimeters','Position',[0,0,20,30],'PaperPositionMode','auto','DefaultTextInterpreter', 'none')
        
        subplot(2,2,1) %signal intensity
        plot(ROIData.t_S,ROIData.([meanMedian{iPlot} 'SI'])(:,iROI),'b.:')
        xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.([meanMedian{iPlot} 'SI'])(:,iROI))-10 max(ROIData.([meanMedian{iPlot} 'SI'])(:,iROI))+10]);
        title([opts.ROILabels{iROI} ' (' meanMedian{iPlot} '):  SI'])
        xlabel('time (s)');

        subplot(2,2,2) %enhancement
        plot(ROIData.t_S,ROIData.([meanMedian{iPlot} '_enhPct'])(:,iROI),'b.:',...
            ROIData.t_S,ROIData.([meanMedian{iPlot} '_fit_enhPct'])(:,iROI),'k-'); hold on;
        xlim([0 max(ROIData.t_S)]); ylim([min(ROIData.([meanMedian{iPlot} '_enhPct'])(:,iROI))-1 max(ROIData.([meanMedian{iPlot} '_enhPct'])(:,iROI))+1]);
        title({[opts.ROILabels{iROI} ' (' meanMedian{iPlot} '): enhancement (%)'] ['slope = ' num2str(ROIData.([meanMedian{iPlot} 'EnhSlope'])(1,iROI)) ' pct per s' ]})
        xlabel('time (s)');
        line([0 max(ROIData.t_S)],[0 0],'LineStyle','-','Color','k')
        
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

end
