function INV_pipe_transformDCEToStruct(opts)
%transform parameter maps to structural space using previously determined
%transform

imagesToTransform={'PatlakFast_PSperMin.nii' 'PatlakFast_vP.nii' 'PatlakFast_vB.nii' 'PatlakFast_k_perMin.nii' ...
    'sPatlakFast_PSperMin.nii' 'sPatlakFast_vP.nii' 'sPatlakFast_vB.nii' 'sPatlakFast_k_perMin.nii' ...
    'bet_PatlakFast_PSperMin.nii' 'bet_PatlakFast_vP.nii' 'bet_PatlakFast_vB.nii' 'bet_PatlakFast_k_perMin.nii' ...
    'bet_sPatlakFast_PSperMin.nii' 'bet_sPatlakFast_vP.nii' 'bet_sPatlakFast_vB.nii' 'bet_sPatlakFast_k_perMin.nii'};
NImages=size(imagesToTransform,2);

if opts.overwrite==0 && exist([opts.DCENIIDir '/r' imagesToTransform{end}],'file'); return; end

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
