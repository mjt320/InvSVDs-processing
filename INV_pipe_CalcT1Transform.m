function INV_pipe_CalcT1Transform(opts)
%calculate transformation to align T1 and k image to first volume of DCE

if opts.overwrite==0 && exist([opts.DCENIIDir '/T1ToDCE.txt'],'file'); return; end

%delete previous output
delete([opts.DCENIIDir '/T1ToDCE.txt']);

system(['flirt -cost normmi -in ' opts.HIFIImg ' -ref ' opts.DCENIIDir '/meanPre -omat ' opts.DCENIIDir '/T1ToDCE.txt']); %calculate transformation from HIFI image to mean pre-contrast DCE image

end
