function INV_pipe_getTSNR(opts)
load([opts.DCENIIDir '/acqPars']);

%%delete existing output files
delete([opts.DCENIIDir '/tNoise.nii']);
delete([opts.DCENIIDir '/tSNR.nii']);

%%load 4D signal intensity 
SI4DHdr=spm_vol([opts.DCENIIDir '/rDCE.nii']);
[SI4D,temp]=spm_read_vols(SI4DHdr);

dims=[size(SI4D,1) size(SI4D,2) size(SI4D,3)];

%%convert 4D to 2D array of time series
SI2D=DCEFunc_reshape(SI4D);

%%calculate noise
[tNoise,tSNR,tSignal]=DCEFunc_getNoise(SI2D,10:size(SI4D,4));

%%write
paramNames={'tNoise' 'tSNR' 'tSignal'};
outputs={tNoise,tSNR,tSignal};
for iOutput=1:size(outputs,2)
    delete([opts.DCENIIDir '/' paramNames{iOutput} '*.*']);
    SPMWrite4D(SI4DHdr(1),DCEFunc_reshape(outputs{iOutput},dims),opts.DCENIIDir,paramNames{iOutput},16);
end

end

