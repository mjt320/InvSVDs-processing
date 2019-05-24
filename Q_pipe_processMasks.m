function Q_pipe_processMasks(opts)
%transform and process masks

if opts.overwrite==0 && exist([opts.QROIDir '/' opts.ROINames{end} '.nii'],'file'); return; end %return is overwrite mode is off and last ROI file exists

NROIs=size(opts.ROINames,2); %number of ROIs

%% make output directory and delete existing output files
mkdir(opts.QROIDir);
delete([opts.QROIDir '/*.*']);

%% loop through ROIs and determine signals, enhancements, concentrations etc.
for iROI=1:NROIs
    if size(dir([opts.maskDir{iROI} '/' opts.maskFile{iROI} '*.*']),1)==0 %skip ROIs where mask doesn't exist
        disp(['Warning! Mask file not found: ' opts.maskDir{iROI} '/' opts.maskFile{iROI}]);
        continue;
    end
    
    if ~isempty(strfind(opts.ROINames{iROI},'NAWM')) 
        NEro = 0; thresh = 0.5;
    else
        NEro = 0; thresh = 0.5;
    end
    
    system(['flirt -in ' opts.maskDir{iROI} '/' opts.maskFile{iROI} ' -ref ' opts.QTargetImagePath ' -out ' opts.QROIDir '/_r_' opts.ROINames{iROI} ' -init ' opts.niftiDir '/struct2Q.txt -applyxfm']); %transform mask
    system(['fslmaths ' opts.QROIDir '/_r_' opts.ROINames{iROI} ' -thr ' num2str(thresh) ' -bin ' opts.QROIDir '/_tr_' opts.ROINames{iROI}]); %threshold mask
    system(['fslmaths ' opts.QROIDir '/_tr_' opts.ROINames{iROI} ' -kernel boxv ' num2str(NEro) ' -ero ' opts.QROIDir '/_etr_' opts.ROINames{iROI}]); %erode mask
    copyfile([opts.QROIDir '/_etr_' opts.ROINames{iROI} '.nii.gz'],[opts.QROIDir '/' opts.ROINames{iROI} '.nii.gz'])
    fslchfiletype_all([opts.QROIDir '/*' opts.ROINames{iROI} '*.*'],'NIFTI');
end

end
