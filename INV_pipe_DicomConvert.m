function INV_pipe_DicomConvert(opts)
%convert to NII

mkdir(opts.DCENIIDir); delete([opts.DCENIIDir '/*.*']);
system(['dcm2niix -f DCE -o ' opts.DCENIIDir ' ' opts.DCEDicomDir]);

end
