function Q_pipe_ROIAnalysis(opts)
%sample quantitative images using ROI mask files
close all;

if opts.overwrite==0 && exist([opts.QROIProcDir '/ROIData.mat'],'file'); return; end

%% make output directory and delete existing output files
mkdir(opts.QROIProcDir); delete([opts.QROIProcDir '/*.*']);

%% derive parameters
NROIs=size(opts.ROINames,2); %number of ROIs excluding AIF
NMaps=size(opts.QMapImagePaths,2);

%% load maps and ROIs
QMaps=cell(1,NMaps);
ROIs=cell(1,NROIs);

for iMap=1:NMaps
    [QMaps{iMap},temp]=spm_read_vols(spm_vol([opts.QMapImagePaths{iMap} '.nii']));
end

for iROI=1:NROIs
    if ~exist([opts.QROIDir '/' opts.ROINames{iROI} '.nii'],'file'); %skip ROIs where mask doesn't exist
        disp(['Warning! ROI not found: ' opts.QROIDir '/' opts.ROINames{iROI} '.nii']);
        continue;
    end
    [ROIs{iROI},temp]=spm_read_vols(spm_vol([opts.QROIDir '/' opts.ROINames{iROI} '.nii']));
end

%% make ROI measurements
for iMap=1:NMaps
    
    %% initialise variables
    ROIData.([opts.varNames{iMap} '_median'])=nan(1,NROIs);
    ROIData.([opts.varNames{iMap} '_mean'])=nan(1,NROIs);
    ROIData.([opts.varNames{iMap} '_SD'])=nan(1,NROIs);
    
    %% loop through ROIs and determine values
    for iROI=1:NROIs
        
        if ~exist([opts.QROIDir '/' opts.ROINames{iROI} '.nii'],'file'); %skip ROIs where mask doesn't exist
            continue;
        end
        
        %% Get ROI values
        temp=measure4D(QMaps{iMap},ROIs{iROI});
        ROIData.([opts.varNames{iMap} '_median'])(1,iROI)=temp.median;
        ROIData.([opts.varNames{iMap} '_mean'])(1,iROI)=temp.mean;
        ROIData.([opts.varNames{iMap} '_SD'])(1,iROI)=temp.SD;
    end
end

%% Save data
save([opts.QROIProcDir '/ROIData'],'ROIData');

end
