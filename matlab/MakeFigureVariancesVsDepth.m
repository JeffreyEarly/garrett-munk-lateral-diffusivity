scaleFactor = 1;
LoadFigureDefaults;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constants
latitude = 33;
f0 = 2 * 7.2921E-5 * sin( latitude*pi/180 );
rho0 = 1025;
g = 9.81;

N0 = 5.2e-3;
L_gm = 1.3e3;
rho = @(z) rho0*(1 + L_gm*N0*N0/(2*g)*(1 - exp(2*z/L_gm)));
L = 4000;

E0 = (1.3e3)*(1.3e3)*(1.3e3)*(5.2e-3)*(5.2e-3)*(6.3e-5);
Bw2 = f0*f0*(2*sqrt(N0*N0-f0*f0)/(pi*f0) - 1);
w2_gm = Bw2*E0/(L_gm*N0*N0);

z = linspace(-L,0,100)';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constants
ReadOverNetwork = 0;
if ReadOverNetwork == 1
    baseURL = '/Volumes/seattle_data1/cwortham/research/nsf_iwv/model_raw/';
else
    baseURL = '/Volumes/Samsung_T5/nsf_iwv/model_raw/';
end
% Version 2 files, from October 2018
NonlinearSteadyStateFile = strcat(baseURL,'EarlyV2_GM_NL_forced_damped');
LinearSteadyStateFile = strcat(baseURL,'EarlyV2_GM_LIN_unforced_damped');

WM = WintersModel(NonlinearSteadyStateFile);
[t,u,v,w,eta] = WM.VariableFieldsFrom3DOutputFileAtIndex(1,'t','u','v','w','zeta');
Euv_model = squeeze(mean(mean(u.^2 + v.^2,1),2));
Eeta_model = squeeze(mean(mean(eta.^2,1),2));
Ew_model = squeeze(mean(mean(w.^2,1),2));

if ~exist('GM','var')
    GM = GarrettMunkSpectrum(rho,[-L 0],latitude);
end
Euv = GM.HorizontalVelocityVariance(z);
Eeta = GM.IsopycnalVariance(z);
Ew = GM.VerticalVelocityVariance(z);
N2 = GM.N2(z);
N = sqrt(N2);

N0_const = N0/2;
GMConst = GarrettMunkSpectrumConstantStratification(N0_const,[-L 0],latitude);
EnergyScale = L/L_gm/2;
Euv_const = EnergyScale*GMConst.HorizontalVelocityVariance(z);
Eeta_const = EnergyScale*GMConst.IsopycnalVariance(z);
Ew_const = EnergyScale*GMConst.VerticalVelocityVariance(z);

FigureSize = [50 50 figure_width_2col+8 225*scaleFactor];
fig1 = figure('Units', 'points', 'Position', FigureSize,'Name','VariancesVsDepth');
set(gcf, 'Color', 'w');
fig1.PaperUnits = 'points';
fig1.PaperPosition = FigureSize;
fig1.PaperSize = [FigureSize(3) FigureSize(4)];

subplot(1,3,1)
plot(1e4*Euv,z), hold on
plot(1e4*Euv_const,z)
plot(1e4*Euv_model,z)
set( gca, 'FontSize', figure_axis_tick_size);
xlabel('E\langle{u^2+v^2}\rangle (cm^2/s^2)', 'FontSize', figure_axis_label_size, 'FontName', figure_font);
ylabel('depth (m)', 'FontSize', figure_axis_label_size, 'FontName', figure_font);
subplot(1,3,2)
plot(Eeta,z), hold on
plot(Eeta_const,z)
plot(Eeta_model,z)
set( gca, 'FontSize', figure_axis_tick_size);
xlabel('E\langle\eta^2\rangle (m^2)', 'FontSize', figure_axis_label_size, 'FontName', figure_font);
set(gca, 'YTick', []);
subplot(1,3,3)
plot(1e4*Ew,z), hold on
plot(1e4*Ew_const,z)
plot(1e4*Ew_model,z)
set( gca, 'FontSize', figure_axis_tick_size);
xlabel('E\langle{w^2}\rangle (cm^2/s^2)', 'FontSize', figure_axis_label_size, 'FontName', figure_font);
set(gca, 'YTick', []);

% plot(1e4*(Euv + Ew + N2.*Eeta)/2,z), hold on
% plot(1e4*(Euv_const + Ew_const + N0_const*N0_const.*Eeta_const)/2,z)
% set( gca, 'FontSize', figure_axis_tick_size);
% xlabel('total energy (cm^2/s^2)', 'FontSize', figure_axis_label_size, 'FontName', figure_font);
% set(gca, 'YTick', []);
% legend('Exponential profile (GM reference)', 'Constant stratification')

packfig(1,3)

FigureSize = [50 50 figure_width_2col+8 225*scaleFactor];
fig1 = figure('Units', 'points', 'Position', FigureSize,'Name','WKB VariancesVsDepth');
set(gcf, 'Color', 'w');
fig1.PaperUnits = 'points';
fig1.PaperPosition = FigureSize;
fig1.PaperSize = [FigureSize(3) FigureSize(4)];

subplot(1,3,1)
plot(1e4*Euv.*(N0./N),z), hold on
plot(1e4*Euv_const.*(N0./N0_const),z)
plot(1e4*Euv_model.*(N0./N0_const),z)
vlines(44,'k--')
set( gca, 'FontSize', figure_axis_tick_size);
xlabel('E\langle{u^2+v^2}\rangle (cm^2/s^2)', 'FontSize', figure_axis_label_size, 'FontName', figure_font);
ylabel('depth (m)', 'FontSize', figure_axis_label_size, 'FontName', figure_font);
xlim([0 1.1*max(1e4*Euv.*(N0./N))])
% title('wkb scaled')

subplot(1,3,2)
plot(Eeta.*(N/N0),z),hold on
plot(Eeta_const*(N0_const/N0),z)
plot(Eeta_model*(N0_const/N0),z)
vlines(53,'k--')
set( gca, 'FontSize', figure_axis_tick_size);
xlabel('E\langle\eta^2\rangle (m^2)', 'FontSize', figure_axis_label_size, 'FontName', figure_font);
set(gca, 'YTick', []);
xlim([0 1.1*max(Eeta.*(N/N0))])

subplot(1,3,3)
plot(1e4*Ew.*(N/N0),z),hold on
plot(1e4*Ew_const*(N0_const/N0),z)
plot(1e4*Ew_model*(N0_const/N0),z)
vlines(1e4*w2_gm,'k--')
set( gca, 'FontSize', figure_axis_tick_size);
xlabel('E\langle{w^2}\rangle (cm^2/s^2)', 'FontSize', figure_axis_label_size, 'FontName', figure_font);
set(gca, 'YTick', []);

packfig(1,3)

E = 0.5*(Euv + Ew + N2.*Eeta);
Etotal = trapz(z,E);

return

figure

subplot(2,1,1)
omega = linspace(-N0,N0,200);
S = GM.HorizontalVelocitySpectrumAtFrequencies([0 -L_gm/2 -L_gm],omega);
plot(omega,S), ylog
ylim([1e-4 1e2])
xlim(1.05*[-N0 N0])
title('horizontal velocity spectra')
xlabel('radians per second')

subplot(2,1,2)
omega = linspace(0,N0,500);
Siso = GM.IsopycnalSpectrumAtFrequencies([0 -L_gm/2 -L_gm],omega);
plot(omega,Siso), ylog, xlog
Sref = omega.^(-2); Sref(omega<f0) = 0; refIndex = find(omega>f0,1,'first'); Sref = Sref * (Siso(2,refIndex)/Sref(refIndex))*10;
hold on, plot(omega,Sref,'k','LineWidth',2)
ylim([1e1 3e6])
xlim(1.05*[0 N0])
title('isopycnal spectra')
xlabel('radians per second')

% subplot(2,2,4)
% omega = linspace(0,N0,500);
% Sw = GM.HorizontalVerticalVelocitySpectrumAtFrequencies(linspace(-500,0,20),omega);
% plot(omega,Sw), ylog, xlog
% ylim([1e-6 1e-1])
% xlim(1.05*[0 N0])
% title('horizontal vertical velocity spectra')
% xlabel('radians per second')


return

k = linspace(0,pi/10,150)';
S = GM.HorizontalVelocitySpectrumAtWavenumbers(k);

S( S<1e-2 ) = 1e-2;
figure, plot(k,S), ylog, xlog
ylim([1e-2 1.1*max(max(S))])