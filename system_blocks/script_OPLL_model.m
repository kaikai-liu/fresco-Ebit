% script_OPLL_model.m

clear;
close all;
load('PDH\data\0416_EFD_CS_SBS','f1','S_CS_SBS1');

%% setting
q = 1.6e-19;
R = 1;                              % PD responsivity [A/W]
r = 1000;                           % TIA gain [V/W]
P_lo = 0; P_lo = 1e-3*10^(P_lo/10); % LO power [dBm]
P_s = -40; P_s = 1e-3*10^(P_s/10);  % sign power [dBm]
K = 2*pi*30e6;                      % optical freq mod [rad/s/V]
BW_vco = 100e6;                     % VCO bandwidth 700kHz [Hz]
% BW_vco = BWx;
Dphi = 2*R*sqrt(P_lo*P_s)*r;        % phase disc [V/rad]

%% noise terms
f = [f1;10.^linspace(5.2,10,100)'];
S_FN = S_CS_SBS1; S_FN = [S_FN;ones(100,1)*S_FN(end)]; % actual CS-SBS laser FN
S_PN = S_FN./f.^2;
% f = linspace(0,10,100)';
% S_PN = 1./f.^2;                   % phase noise of signal and LO
Id = 1e-12;                         % PD dark current noise [A/rtHz]
S_pd = Id^2*r^2/Dphi^2;             % PD noise [rad^2/Hz]
S_sh = 2*q*R*P_lo*r^2/Dphi^2;       % shot noise [rad^2/Hz]

S_pd = S_pd*ones(size(f)); 
S_sh = S_sh*ones(size(f));

% add to noises
noises.S_P = S_PN;
noises.S_D = (S_pd + S_sh)*Dphi^2;

%% control model
s = tf('s');
syss.f = f;
syss.D = Dphi;
syss.P = K/s/(1+s/(2*pi*BW_vco));
syss.output = 'P';
[syss_out,S_out] = func_feedback_loop(syss,noises);
H_f = syss_out.H_f;
H_rej = syss_out.N_P;
H_D = syss_out.N_D;
S_resi = S_out;
phi_res = sum(S_resi(2:end).*diff(f));

%% bode and noise plot
figure;
semilogx(f,20*log10(abs(H_rej)),f,20*log10(abs(H_D))); grid on;
xlabel('Frequency(Hz)'); ylabel('Magnitude(dB)');
legend('LO Noise Rejection','PD Noise Rejection');

figure;
semilogx(f,10*log10([S_PN,S_sh,S_pd]));
hold on;
semilogx(f,10*log10(S_resi),'LineWidth',1.5);
xlabel('Freq offset(Hz)');
ylabel('L_\phi(dBc/Hz)'); %ylim([0.1,1e9]);
title(['OPLL with \sigma^2_\phi=' num2str(phi_res) ' rad^2']);
legend('PN of LO/s','shot noise','PD noise','residual phase noise');

%% sweep BW
BWx = 10.^linspace(3,8,50)';
y = zeros(size(BWx));

for i = 1:length(BWx)
    BW_vco = BWx(i);
    syss.P = K/s/(1+s/(2*pi*BW_vco)); % update VCO bandwidth
    [syss_out,S_out] = func_feedback_loop(syss,noises);
    S_resi = S_out;
    phi_res = sum(S_resi(2:end).*diff(f));
    y(i) = phi_res;
end

% plot residul pahse error vs BW
figure;
loglog(BWx,y); grid on;
xlabel('loop bandwidth(Hz)');
ylabel('\sigma_\phi^2(rad^2)');
title('Residual phase error vs loop bandwidth');