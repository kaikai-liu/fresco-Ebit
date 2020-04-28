function [syss_out,S_out] = func_feedback_loop(syss,noises)
%This functions optimize the PID control based on the discriminator and
%plant.
%Args:
%   syss: structural variable with tf
%       syss.f: frequency grid [Hz]
%       syss.D: discriminitor tf [V/Hz] if PDH [V/rad] if OPLL 
%       syss.C: control sys PID [V/V]
%       syss.P: the plant tf can be the laser [Hz/V] or the SSB VCO [rad/V]
%       syss.outut: output port, 'D','C' or 'P'
%   noises: structural variable with noise terms
%       noises.f: frequency offset for the PSD [Hz]
%       noises.S_R: PSD from the reference signal [V^2/Hz]
%       noises.S_D: PSD added by the disc [V^2/Hz]
%       noises.S_C: PSD added by the control PID [V^2/Hz]
%       noises.S_P: PSD added by the plant [V^2/Hz]
%Return:
%   syss_out: tf evaluation with freq offset f
%   S_out: noise output


% noise terms
if isfield(noises,'S_R')
    S_R = noises.S_R;
else
    S_R = 0;
end
if isfield(noises,'S_D')
    S_D = noises.S_D;
else
    S_D = 0;
end
if isfield(noises,'S_C')
    S_C = noises.S_C;
else
    S_C = 0;
end
if isfield(noises,'S_P')
    S_P = noises.S_P;
else
    S_P = 0;
end

% tune PID and noise tf
f = syss.f;
D = syss.D*tf(1);
P = syss.P*tf(1);
if isfield(syss,'C')
    C = syss.C;             % C is given
else
    C = pidtune(P*D,pidstd(1,1,1)); % C is a tuned PID
end
% close loop tf and equa input noise for output port
den = 1+D*C*P;
D_f = reshape(freqresp(D,1i*2*pi*f),size(f));
C_f = reshape(freqresp(C,1i*2*pi*f),size(f));
P_f = reshape(freqresp(P,1i*2*pi*f),size(f));
switch syss.output
    case 'D'
        H = D/den; H_f = reshape(freqresp(H,1i*2*pi*f),size(f));
        N_R = H_f; N_D = H_f./D_f; N_C = H_f.*P_f; N_P = H_f;
    case 'C'
        H = D*C/den; H_f = reshape(freqresp(H,1i*2*pi*f),size(f));
        N_R = H_f; N_D = H_f./D_f; N_C = H_f./(D_f.*C_f); N_P = H_f;
    case 'P'
        H = D*C*P/den; H_f = reshape(freqresp(H,1i*2*pi*f),size(f));
        N_R = H_f; N_D = H_f./D_f; N_C = H_f./(D_f.*C_f); N_P = H_f./(D_f.*C_f.*P_f);
end
S_out = S_R.*abs(N_R).^2+S_D.*abs(N_D).^2+S_C.*abs(N_C).^2+S_P.*abs(N_P).^2;

% return
syss_out.f = f;
syss_out.D = D;
syss_out.C = C;
syss_out.P = P;
syss_out.H = H;
syss_out.H_f = H_f;
syss_out.N_R = N_R;
syss_out.N_D = N_D;
syss_out.N_C = N_C;
syss_out.N_P = N_P;
end

