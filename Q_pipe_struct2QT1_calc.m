function Q_pipe_struct2QT1_calc(opts)
%co-register structural image to quantitative

if opts.overwrite==0 && exist([opts.niftiDir '/struct2Q.txt'],'file'); return; end

%% make output directory and delete existing output files
delete([opts.niftiDir '/struct2Q.txt']);

%% calculate transformation from structural image (in which masks are defined) and meanPre DCE image
system(['flirt -cost normmi -usesqform -in ' opts.structImagePath ' -ref ' opts.QTargetImagePath ' -omat ' opts.niftiDir '/struct2Q.txt']); %calculate transformation from structural image to target image

end
