function INV_pipe_DicomConvert(opts)
%convert to NII

if opts.overwrite==0 && exist([opts.DCENIIDir '/DCE.nii'],'file'); return; end

mkdir(opts.DCENIIDir); delete([opts.DCENIIDir '/*.*']);
system(['dcm2niix -f DCE -o ' opts.DCENIIDir ' ' opts.DCEDicomDir]);

end
