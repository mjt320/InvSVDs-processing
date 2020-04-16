function INV_pipe_ApplyT1Transform_NN(opts)
%transform T1 and k images to DCE space

if opts.overwrite==0 && exist([opts.DCENIIDir '/rk.nii'],'file'); return; end

%delete previous output
delete([opts.DCENIIDir '/rT1*.*']);
delete([opts.DCENIIDir '/rk*.*']);

%check transformation matrix is available
if ~exist([opts.DCENIIDir '/T1ToDCE.txt'],'file'); error('Transformation matrix not found!'); end

system(['flirt -interp nearestneighbour -in ' opts.T1MapFile ' -ref ' opts.DCENIIDir '/meanPre -out ' opts.DCENIIDir '/rT1 -init ' opts.DCENIIDir '/T1ToDCE.txt -applyxfm']); %transform T1 map
system(['flirt -interp nearestneighbour -in ' opts.kMapFile ' -ref ' opts.DCENIIDir '/meanPre -out ' opts.DCENIIDir '/rk -init ' opts.DCENIIDir '/T1ToDCE.txt -applyxfm']); %transform k map
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rT1']); %change to .nii
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rk']);

end
