function INV_pipe_getAcqPars(opts)
%read dicom headers

if opts.overwrite==0 && exist([opts.DCENIIDir '/acqPars.mat'],'file'); return; end

dicoms=dir([opts.DCEDicomDir '/*.dcm']);
if isempty(dicoms); dicoms=dir([opts.DCEDicomDir '/*.IMA']); end

%% take parameters from first dicom
dcmhdr=dicominfo([opts.DCEDicomDir '/' dicoms(1).name]);
acqPars.TR_s=dcmhdr.RepetitionTime / 1000;
acqPars.TE_s=dcmhdr.EchoTime / 1000;
acqPars.FA_deg=dcmhdr.FlipAngle;
acqPars.tRes_s=str2num(dcmhdr.Private_0051_100a(4:end));

%% calculate number of frames from 4D NII
acqPars.DCENFrames=size(spm_vol([opts.DCENIIDir '/DCE.nii']),1);

disp(['TR (s): ' num2str(acqPars.TR_s) ' TE (s): ' num2str(acqPars.TE_s) ' FA (deg): ' num2str(acqPars.FA_deg) ' tRes (s): ' num2str(acqPars.tRes_s) ' DCE frames: ' num2str(acqPars.DCENFrames)]);

delete([opts.DCENIIDir '/acqPars.mat']);
save([opts.DCENIIDir '/acqPars'],'acqPars');

end
