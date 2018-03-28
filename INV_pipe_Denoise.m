function INV_pipe_Denoise(opts)

SI4DHdr=spm_vol([opts.DCENIIDir '/rDCE.nii']); %load co-reg data to calculate mean pre-contrast image
[SI4D,temp]=spm_read_vols(SI4DHdr);

dims=[size(SI4D,1) size(SI4D,2) size(SI4D,3)];

NFrames=size(SI4D,4);

%%convert 4D to 2D array of time series
SI2D=DCEFunc_reshape(SI4D);


MP=load([opts.DCENIIDir '/rDCE.par']);

temp=zeros(size(MP));
temp(2:end,:)=MP(1:end-1,:);
MPd=MP-temp;


%reg = [ones(NFrames,1) MP];
%reg = [ones(NFrames,1) MP MP.^2 MPd MPd.^2];
fullReg=detrend([MP MP.^2 MPd MPd.^2]);
partialReg=detrend(fullReg(10:end,:));
Y=detrend(SI2D(10:end,:));


beta = partialReg \ Y;

SI2D_clean=SI2D - fullReg * beta;

SPMWrite4D(SI4DHdr,DCEFunc_reshape(SI2D_clean,dims),opts.DCENIIDir,'crDCE',SI4DHdr(1).dt);

end
