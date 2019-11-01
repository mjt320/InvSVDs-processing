function INV_pipe_processMasks(opts)
%transform and process masks

%return if overwrite mode is off and last ROI file exists...
if opts.overwrite==0 && exist([opts.DCEROIDir '/' opts.ROINames{end} '.nii'],'file'); return; end 

NROIs=size(opts.ROINames,2); %number of ROIs

%% make output directory and delete existing output files
mkdir(opts.DCEROIDir);
delete([opts.DCEROIDir '/*.*']);

%% loop through ROIs and determine signals, enhancements, concentrations etc.
for iROI=1:NROIs
    if size(dir([opts.maskDir{iROI} '/' opts.maskFile{iROI} '*.*']),1)==0 %skip ROIs where mask doesn't exist
        disp(['Warning! Mask file not found: ' opts.maskDir{iROI} '/' opts.maskFile{iROI}]);
        continue;
    end
    
    system(['flirt -in ' opts.maskDir{iROI} '/' opts.maskFile{iROI} ' -ref ' opts.DCENIIDir '/meanPre -out ' opts.DCEROIDir '/_r_' opts.ROINames{iROI} ' -init ' opts.DCENIIDir '/struct2DCE.txt -applyxfm']); %transform mask (just for checking)
    system(['fslmaths ' opts.DCEROIDir '/_r_' opts.ROINames{iROI} ' -thr ' num2str(opts.maskTheshold (iROI)) ' -bin ' opts.DCEROIDir '/_tr_' opts.ROINames{iROI} ' -odt char']); %threshold mask (just for checking)
    
    system(['fslmaths ' opts.maskDir{iROI} '/' opts.maskFile{iROI} ' -kernel boxv ' num2str(opts.maskNErodePre(iROI)) ' -ero ' opts.DCEROIDir '/_e_' opts.ROINames{iROI}]); %erode mask in structural space            
    system(['flirt -in ' opts.DCEROIDir '/_e_' opts.ROINames{iROI} ' -ref ' opts.DCENIIDir '/meanPre -out ' opts.DCEROIDir '/_re_' opts.ROINames{iROI} ' -init ' opts.DCENIIDir '/struct2DCE.txt -applyxfm']); %transform mask
    system(['fslmaths ' opts.DCEROIDir '/_re_' opts.ROINames{iROI} ' -thr ' num2str(opts.maskTheshold (iROI)) ' -bin ' opts.DCEROIDir '/_tre_' opts.ROINames{iROI} ' -odt char']); %threshold mask
    system(['fslmaths ' opts.DCEROIDir '/_tre_' opts.ROINames{iROI} ' -kernel boxv ' num2str(opts.maskNErode(iROI)) ' -ero ' opts.DCEROIDir '/_etre_' opts.ROINames{iROI}]); %erode mask in DCE space      
    fslchfiletype_all([opts.DCEROIDir '/*' opts.ROINames{iROI} '*.*'],'NIFTI');    
    copyfile([opts.DCEROIDir '/_etre_' opts.ROINames{iROI} '.nii'],[opts.DCEROIDir '/' opts.ROINames{iROI} '.nii'])
end

end
