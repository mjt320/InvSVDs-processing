function INV_pipe_transformDCEToStruct(opts)
%transform parameter maps to structural space using previously determined
%transform

imagesToTransform={'PatlakFast_PSperMin.nii' 'PatlakFast_vP.nii' 'sPatlakFast_PSperMin.nii' 'sPatlakFast_vP.nii'};
NImages=size(imagesToTransform,2);

if opts.overwrite==0 && exist([opts.DCENIIDir '/DCE2Struct.txt'],'file'); return; end

%% delete existing output files
delete([opts.DCENIIDir '/DCE2Struct.txt']);
for n=1:NImages
    delete([opts.DCENIIDir '/r' imagesToTransform{n} '.*']);
end


%% calculate inverse transformation of struct2DCE and apply to parameter maps
system(['convert_xfm -omat ' opts.DCENIIDir '/DCE2Struct.txt -inverse ' opts.DCENIIDir '/struct2DCE.txt']);

for n=1:NImages
    system(['flirt -in ' opts.DCENIIDir '/' imagesToTransform{n} ' -ref ' opts.structImagePath ' -out ' opts.DCENIIDir '/r' imagesToTransform{n} ' -init ' opts.DCENIIDir '/DCE2Struct.txt -applyxfm']);
    system(['fslchfiletype NIFTI ' opts.DCENIIDir '/r' imagesToTransform{n}]); %change to .nii
end

end
