function INV_pipe_genMaskOverlays(opts)
close all;

%% delete existing output files
if exist([opts.DCENIIDir '/overlays'],'dir')
    delete([opts.DCENIIDir '/overlays/*']);
else
    mkdir([opts.DCENIIDir '/overlays'])
end

slice = 50;
meanDCE=spm_read_vols(spm_vol([opts.DCENIIDir '/meanPre.nii']));
NROIs=size(opts.ROINames,2);

NSlices = size(meanDCE,2);

outputSlices = round(linspace(1,NSlices,12));
outputSlices = outputSlices(6:9);

for iROI=1:NROIs
    
    if ~exist([opts.DCEROIDir '/' opts.ROINames{iROI} '.nii'],'file') %skip ROIs where mask doesn't exist
        disp(['Warning! ROI not found: ' opts.DCEROIDir '/' opts.ROINames{iROI} '.nii']);
        continue;
    else
        [masks{iROI},temp] = spm_read_vols(spm_vol([opts.DCEROIDir '/' opts.ROINames{iROI} '.nii']));
    end
    
    for slice = outputSlices
        im_slice=squeeze(meanDCE(:,slice,:));
        mask_slice=squeeze(masks{iROI}(:,slice,:));
        imagesc(im_slice.*(1-mask_slice));
        colormap(gray(256));
        saveas(1,[opts.DCENIIDir '/overlays/overlay_dce_' opts.subjectCode '_' opts.ROINames{iROI} '_' num2str(slice) '.jpg']);
    end
    
end

end