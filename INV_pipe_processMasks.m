function INV_pipe_processMasks(opts)
%transform and process masks

if opts.overwrite==0 && ~isempty(dir([opts.DCEROIDir '/r' opts.ROINames{end} '*.*'])); return; end %return is overwrite mode is off and last ROI file exists

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
    
    if ~isempty(strfind(opts.ROINames{iROI},'NAWM')) 
        NEro = 0; thresh = 0.5;
    else
        NEro = 0; thresh = 0.5;
    end
    
    system(['flirt -in ' opts.maskDir{iROI} '/' opts.maskFile{iROI} ' -ref ' opts.DCENIIDir '/meanPre -out ' opts.DCEROIDir '/_r_' opts.ROINames{iROI} ' -init ' opts.DCENIIDir '/struct2DCE.txt -applyxfm']); %transform mask
    system(['fslmaths ' opts.DCEROIDir '/_r_' opts.ROINames{iROI} ' -thr ' num2str(thresh) ' -bin ' opts.DCEROIDir '/_tr_' opts.ROINames{iROI}]); %threshold mask
    system(['fslmaths ' opts.DCEROIDir '/_tr_' opts.ROINames{iROI} ' -kernel boxv ' num2str(NEro) ' -ero ' opts.DCEROIDir '/_etr_' opts.ROINames{iROI}]); %erode mask
    copyfile([opts.DCEROIDir '/_etr_' opts.ROINames{iROI} '.nii.gz'],[opts.DCEROIDir '/' opts.ROINames{iROI} '.nii.gz'])
    fslchfiletype_all([opts.DCEROIDir '/*' opts.ROINames{iROI} '*.*'],'NIFTI');
end

end
