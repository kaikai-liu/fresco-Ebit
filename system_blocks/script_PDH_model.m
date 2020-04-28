clear; close all;
load('PDH\data\0402_FN_data.mat')
load('PDH\data\0305_ML_freq_resp_tf.mat')

%% settings
q = 1.6e-19;            % electron charge
R = 1;                  % PD responsivity, in A/W
Rv = 125000;            % PD TIA gain, in V/A
Pin = -10;              % input PD power, in dBm
Pin = 1e-3*10^(Pin/10);
Id = 7e-12;             % PD dark current noise, in A/rtHz
Dv = 1e-6;                 % discrimination slope [V/Hz]

%% PD noise
S_pd = Id^2*Rv^2/Dv^2;              % PD dark current noise [Hz^2/Hz]
S_sh = 2*q*R*Pin*Rv^2/Dv^2;         % shot noise [Hz^2/Hz]
S_pd = S_pd*ones(size(f));
S_sh = S_sh*ones(size(f));
% add to noises
noises.S_R = S_TRN;
noises.S_D = (S_pd + S_sh)*Dv^2;
noises.S_P = S_ML;

%% loop transfer function
% laser tuning, Dv, add to syss
syss.f = f;
syss.D = Dv;
syss.P = sys*1e6;                   % x1e6 convert MHz/V to Hz/V
syss.C = pidtune(Dv*sys,pidstd(1,1,1));
s = tf('s');
syss.C = 0.264*(1+1.4e6/s+1e-9*s);

% specify output as the laser output
syss.output = 'P';
[syss_out,S_out] = func_feedback_loop(syss,noises);
H = syss_out.H_f;
H_rej = syss_out.N_P;
S_y = S_out;
S_resi = S_ML.*abs(H_rej).^2;


%% bode and noise plot
figure;
h = bodeplot(syss.C,10.^linspace(2,11,100)); setoptions(h,'FreqUnits','Hz','PhaseVisible','off');
grid on;
title('servo transfer function');


%%
figure;
semilogx(f,20*log10(abs(H)),f,20*log10(abs(H_rej))); grid on;
xlabel('Frequency(Hz'); ylabel('Magnitude(dB)'); title('PDH Lock');
legend('Refercence Tracking','Input Noise Rejection');

figure;
loglog(f,[S_ML,S_TRN,S_sh,S_pd]); hold on;
loglog(f,[S_resi S_y],'LineWidth',1.5); ylim([1e-2,1e9]);
xlabel('Frequency(Hz)'); ylabel('FN(Hz^2/Hz)'); title('Frequency Noise');
legend('Laser noise','Cavity noise','shot noise','PD noise',...
    'Residual laser noise','Close loop totol noise');

%% compare the actual residual FN
% Dv_resi = 1.5e-4;
% file1 = 'PDH\data\residual_FN_RP_1.csv';
% file2 = 'PDH\data\residual_FN_RP_2.csv';
% S_resi1 = readmatrix(file1);
% f1 = 10.^(S_resi1(3:end,1));
% S_resi1 = 10.^(S_resi1(3:end,2))/Dv_resi^2;
% S_resi2 = readmatrix(file2); 
% f2 = 10.^(S_resi2(3:end,1));
% S_resi2 = 10.^(S_resi2(3:end,2))/Dv_resi^2;
% loglog(f2,S_resi2)