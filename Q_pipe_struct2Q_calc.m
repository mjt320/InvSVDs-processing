function Q_pipe_struct2QT1_calc(opts)
%co-register structural image to quantitative

if opts.overwrite==0 && ( exist([opts.niftiDir '/struct2Q.txt'],'file') || exist([opts.niftiDir '/rStructImage.xfmb'],'dir') ); return; end

if ~isfield(opts,'structCoRegMode'); opts.structCoRegMode=0; end %use default co-reg mode

%% make output directory and delete existing output files
delete([opts.niftiDir '/struct2Q.txt']);
if exist([opts.niftiDir '/rStructImage.xfmb'],'dir')
    delete([opts.niftiDir '/rStructImage.xfmb/*']);
    rmdir([opts.niftiDir '/rStructImage.xfmb']);
end

%% calculate transformation from structural image (in which masks are defined) and meanPre DCE image

if isfield(opts,'struct2QMat') && ~isempty(opts.struct2QMat) %if the transformation has already been specified, just copy that file
    copyfile(opts.struct2QMat,[opts.niftiDir '/struct2Q.txt']);
else %otherwise, calculate the transformation
    switch opts.structCoRegMode
        case 0
            system(['flirt -cost normmi -usesqform -in ' opts.structImagePath ' -ref ' opts.QTargetImagePath ' -omat ' opts.niftiDir '/struct2Q.txt']); %calculate transformation from structural image to target image
        case 4
            system(['tractor reg-linear ' opts.structImagePath ' ' opts.QTargetImagePath ' EstimateOnly:true TransformName:' opts.niftiDir '/rStructImage'] );
        otherwise
            error('Struct co-reg mode not recognised.');
    end
end

end
