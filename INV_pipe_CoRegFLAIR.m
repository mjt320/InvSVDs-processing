function INV_pipe_CoRegFLAIR(opts)

if opts.overwrite==0 && exist([opts.DCENIIDir '/r3DFLAIR.nii'],'file'); return; end

delete([opts.DCENIIDir '/*FLAIR*.*']);

inFile=['../STRUCTURAL_IMAGE_PROCESSING/' opts.subjectCode '/3DFLAIR'];
matFile=[opts.DCENIIDir '/3DFLAIR2Mean.txt'];
outFile=[opts.DCENIIDir '/r3DFLAIR'];
refFile=[opts.DCENIIDir '/meanPre'];

system(['flirt -cost normmi '...
    ' -in ' inFile ' -ref ' refFile ' -out ' outFile ' -omat ' matFile ' -dof 12']);

system(['fslchfiletype NIFTI ' outFile]);

end
