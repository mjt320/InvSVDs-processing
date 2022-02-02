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
    
    if opts.structCoRegMode == 4
        system(['tractor reg-apply ' opts.maskDir{iROI} '/' opts.maskFile{iROI} ' ' opts.QROIDir '/_r_' opts.ROINames{iROI} ' TransformName:' opts.niftiDir '/rStructImage.xfmb'])
    else
        system(['flirt -in ' opts.maskDir{iROI} '/' opts.maskFile{iROI} ' -ref ' opts.QTargetImagePath ' -out ' opts.QROIDir '/_r_' opts.ROINames{iROI} ' -init ' opts.niftiDir '/struct2Q.txt -applyxfm']); %transform mask
    end
    system(['fslmaths ' opts.QROIDir '/_r_' opts.ROINames{iROI} ' -thr ' num2str(opts.maskTheshold (iROI)) ' -bin ' opts.QROIDir '/_tr_' opts.ROINames{iROI}]); %threshold mask
    
    system(['fslmaths ' opts.maskDir{iROI} '/' opts.maskFile{iROI} ' -kernel boxv ' num2str(opts.maskNErodePre(iROI)) ' -ero ' opts.QROIDir '/_e_' opts.ROINames{iROI}]); %erode mask in structural space
    if opts.structCoRegMode ==4
        system(['tractor reg-apply ' opts.QROIDir '/_e_' opts.ROINames{iROI} ' ' opts.QROIDir '/_re_' opts.ROINames{iROI} ' TransformName:' opts.niftiDir '/rStructImage.xfmb'])
    else
        system(['flirt -in ' opts.QROIDir '/_e_' opts.ROINames{iROI} ' -ref ' opts.QTargetImagePath ' -out ' opts.QROIDir '/_re_' opts.ROINames{iROI} ' -init ' opts.niftiDir '/struct2Q.txt -applyxfm']); %transform mask
    end
    system(['fslmaths ' opts.QROIDir '/_re_' opts.ROINames{iROI} ' -thr ' num2str(opts.maskTheshold(iROI)) ' -bin ' opts.QROIDir '/_tre_' opts.ROINames{iROI} ' -odt char']); %threshold mask
    system(['fslmaths ' opts.QROIDir '/_tre_' opts.ROINames{iROI} ' -kernel boxv ' num2str(opts.maskNErode(iROI)) ' -ero ' opts.QROIDir '/_etre_' opts.ROINames{iROI}]); %erode mask in Q space
    
    fslchfiletype_all([opts.QROIDir '/*' opts.ROINames{iROI} '*.*'],'NIFTI');
    copyfile([opts.QROIDir '/_etre_' opts.ROINames{iROI} '.nii'],[opts.QROIDir '/' opts.ROINames{iROI} '.nii'])
    
end

end
