function INV_pipe_TransformT1(opts)
%align T1 and k image to first volume of DCE

if opts.overwrite==0 && exist([opts.DCENIIDir '/rT1.nii'],'file'); return; end

%delete previous output
delete([opts.DCENIIDir '/rT1*.*']);
delete([opts.DCENIIDir '/rk*.*']);
delete([opts.DCENIIDir '/T1ToDCE.txt']);

system(['flirt -cost normmi -in ' opts.HIFIImg ' -ref ' opts.DCENIIDir '/meanPre -omat ' opts.DCENIIDir '/T1ToDCE.txt']); %calculate transformation from HIFI image to mean pre-contrast DCE image
system(['flirt -in ' opts.T1MapFile ' -ref ' opts.DCENIIDir '/meanPre -out ' opts.DCENIIDir '/rT1 -init ' opts.DCENIIDir '/T1ToDCE.txt -applyxfm']); %transform T1 map
system(['flirt -in ' opts.kMapFile ' -ref ' opts.DCENIIDir '/meanPre -out ' opts.DCENIIDir '/rk -init ' opts.DCENIIDir '/T1ToDCE.txt -applyxfm']); %transform k map
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rT1']); %change to .nii
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rk']);

end
