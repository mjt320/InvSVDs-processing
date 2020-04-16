function INV_pipe_ApplyT1Transform(opts)
%transform T1 and k images to DCE space

if opts.overwrite==0 && exist([opts.DCENIIDir '/rk.nii'],'file'); return; end

%delete previous output
delete([opts.DCENIIDir '/rT1*.*']);
delete([opts.DCENIIDir '/rk*.*']);

%check transformation matrix is available
if ~exist([opts.DCENIIDir '/T1ToDCE.txt'],'file'); error('Transformation matrix not found!'); end

%zero nans in T1 map so that they can be excluded by flirt during resampling
zT1MapFile=[opts.DCENIIDir '/zT1'];
zkMapFile=[opts.DCENIIDir '/zk'];
system(['fslmaths ' opts.T1MapFile ' -nan ' zT1MapFile]);
system(['fslmaths ' opts.kMapFile ' -nan  ' zkMapFile]);

%transform maps
system(['flirt -interp trilinear -setbackground 0 -in ' zT1MapFile ' -ref ' opts.DCENIIDir '/meanPre -out ' opts.DCENIIDir '/rT1 -init ' opts.DCENIIDir '/T1ToDCE.txt -applyxfm']); %transform T1 map
system(['flirt -interp trilinear -setbackground 0 -in ' zkMapFile ' -ref ' opts.DCENIIDir '/meanPre -out ' opts.DCENIIDir '/rk -init ' opts.DCENIIDir '/T1ToDCE.txt -applyxfm']); %transform k map
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rT1']); %change to .nii
system(['fslchfiletype NIFTI ' opts.DCENIIDir '/rk']);

%replace zeros with nans
spm_imcalc([opts.DCENIIDir '/rT1.nii'],[opts.DCENIIDir '/rT1.nii'],'i1.*(i1./i1)',struct('dtype',16))
spm_imcalc([opts.DCENIIDir '/rk.nii'],[opts.DCENIIDir '/rk.nii'],'i1.*(i1./i1)',struct('dtype',16))

delete(zT1MapFile);
delete(zkMapFile);
end
