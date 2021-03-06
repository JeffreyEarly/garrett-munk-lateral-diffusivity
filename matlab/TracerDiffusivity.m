runtype = 'nonlinear';
ReadOverNetwork = 1;

if ReadOverNetwork == 1
    baseURL = '/Volumes/seattle_data1/cwortham/research/nsf_iwv/model_raw/';
else
    baseURL = '/Volumes/Samsung_T5/nsf_iwv/2018_12/';
%     baseURL = '/Users/jearly/Documents/ManuscriptRepositories/garrett-munk-lateral-diffusivity/data/2018_11/';
end

if strcmp(runtype,'linear')
    file = strcat(baseURL,'EarlyV2_GM_LIN_unforced_damped_restart');
elseif strcmp(runtype,'nonlinear')
    file = strcat(baseURL,'EarlyV2_GM_NL_forced_damped_restart');
else
    error('invalid run type.');
end

outputfile = sprintf('%stracer_sheet_%s.mat',baseURL,runtype);

if ~exist(outputfile,'file')
    WM = WintersModel(file);
    wavemodel = WM.wavemodel;
    
    s2 = WM.VariableFieldsFrom3DOutputFileAtIndex(1,'s2');
    
    dx = WM.wavemodel.x(2)-WM.wavemodel.x(1);
    dy = WM.wavemodel.y(2)-WM.wavemodel.y(1);
    dz = WM.wavemodel.z(2)-WM.wavemodel.z(1);
    X = WM.wavemodel.X;
    Y = WM.wavemodel.Y;
    Z = WM.wavemodel.Z;
    
    dV = dx*dy*dz;

    nFiles = WM.NumberOf3DOutputFiles;
    fileIncrements = 1:1:nFiles;
    
    nT = length(fileIncrements);
    nZ = length(wavemodel.z);
    t = zeros(nT,1);
    m = zeros(nT,nZ);
    m_x = zeros(nT,nZ);
    m_y = zeros(nT,nZ);
    m_xx = zeros(nT,nZ);
    m_xy = zeros(nT,nZ);
    m_yy = zeros(nT,nZ);
    startTime = datetime('now');
    for iFile = 1:length(fileIncrements)
        if mod(iFile,10) == 2
            timePerStep = (datetime('now')-startTime)/(iFile-1);
            timeRemaining = (nT-iFile+1)*timePerStep;
            fprintf('reading values time step %d of %d to file. Estimated finish time %s (%s from now)\n', iFile, nT, datestr(datetime('now')+timeRemaining), datestr(timeRemaining, 'HH:MM:SS')) ;
        end
        
        file = WM.PathOf3DOutputFileAtIndex(fileIncrements(iFile));
        [s2,t(iFile)] = WM.VariableFieldsFrom3DOutputFileAtIndex(iFile,'s2','time');
        
        %     t(iFile) = double(ncread(file,'time'));
        
        m(iFile,:) = sum(sum(s2,1),2)*dV;
        m_reshape = reshape(m(iFile,:),[],1);
        
        m_x(iFile,:) = reshape(sum(sum(X.*s2,1),2),[],1)*dV./m_reshape;
        m_y(iFile,:) = reshape(sum(sum(Y.*s2,1),2),[],1)*dV./m_reshape;
        
        Xc = X-m_x(iFile);
        Yc = Y-m_y(iFile);

        m_xx(iFile,:) = reshape(sum(sum(Xc.*Xc.*s2,1),2),[],1)*dV./m_reshape;
        m_xy(iFile,:) = reshape(sum(sum(Xc.*Yc.*s2,1),2),[],1)*dV./m_reshape;
        m_yy(iFile,:) = reshape(sum(sum(Yc.*Yc.*s2,1),2),[],1)*dV./m_reshape;
    end
    save(outputfile,'t','m','m_x', 'm_y','m_xx','m_xy','m_yy');
else
    load(outputfile);
end

D2 = (m_xx+m_yy)/2;

return

% [xbar,f]  = FourierTransformForward(t,(m_xx+m_yy)/2,1);
% figure, plot(f,abs(xbar).^2),ylog
% S = abs(xbar).^2;
% xbar(S>1e12) = 0;
% 
% x_back = FourierTransformBack(f,xbar,1);
% figure, plot(t,x_back)
% hold on, plot(t, D2 -mean(D2))
% indices= 200:1100;

N_osc = 13;
filter_size = ceil(length(t)/N_osc);
filter_size = 1;
D2_filtered = RunningFilter(D2,filter_size,'mean');
Mzz_filtered = RunningFilter(m_zz,filter_size,'mean');
validIndices = ceil(filter_size/2):(length(t)-ceil(filter_size/2));

X = t(validIndices);
Y = D2_filtered(validIndices);
Z = Mzz_filtered(validIndices);

% X = t;
% Y = D2;


[D2_coeff,D2_err] = LinearLeastSquaresFit(X,Y);
[Mzz_coeff,Mzz_err] = LinearLeastSquaresFit(X,Z);

[p,~,mu]=polyfit(X,Y,1);
kappa_xy = (p(1)/mu(2))/2;

[p,~,mu]=polyfit(X,Z,1);
kappa_z = (p(1)/mu(2))/2;

% X = t(indices);
% Y = x_back(indices);




figure('Name',sprintf('LateralDiffusivityOfTracer-%s',runtype))
subplot(3,1,1)
plot(t/86400,m/m(1))
ylabel('total mass')
subplot(3,1,2)
plot(t/86400,[m_x, m_y]/1e3)
legend('x','y')
ylabel('km')
subplot(3,1,3)
plot(t/86400,D2/1e6), hold on
plot(t/86400,D2_filtered/1e6,'LineWidth',2)
plot(X/86400,(D2_coeff(2)*X+D2_coeff(1))/1e6,'k--')
legend('D2','D2 filtered','linear fit')
title(sprintf('isotropic diffusivity %.2f +/- %.2f m^2/s at scale %.0f km',D2_coeff(2)/2,D2_err(2), sqrt(D2(1))/1e3 ));
ylabel('km^2')
print('-depsc',sprintf('TracerLateral-%s.eps',runtype))

figure('Name',sprintf('VerticalDiffusivityOfTracer-%s',runtype))
subplot(2,1,1)
plot(t/86400,m_z)
ylabel('m')
subplot(2,1,2)
plot(t/86400,m_zz), hold on
plot(X/86400,Z,'LineWidth',2)
title(sprintf('isotropic diffusivity %.2g +/- %.2g m^2/s at scale %.2f m',Mzz_coeff(2)/2,Mzz_err(2), sqrt(m_zz(1)) ));
ylabel('m^2')
print('-depsc',sprintf('TracerVertical-%s.eps',runtype))