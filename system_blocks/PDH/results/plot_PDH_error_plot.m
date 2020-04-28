% PDH_error.m

clear;

FSR = 100;             % FSR, in MHz
F = 400e3;              % Finess
R = 1 - 2/sqrt(F);      % reflectivity
fm = 20;                % PM freq, in MHz
phi_mx = pi*2/4;        % phase of mixer

df = -100:0.01:100;

e_sig = Frefl(df/FSR,R).*conj(Frefl((df+fm)/FSR,R)) - conj(Frefl(df/FSR,R)).*Frefl((df-fm)/FSR,R);
mag = abs(e_sig);
phi_df = angle(e_sig);
% plot(df,abs(e_sig));

% subplot(2,2,4);
figure;
plot(df,mag.*cos(phi_df - phi_mx)); grid on;
xlabel('Frequency detuning(MHz)'); ylabel('P_r/2J_0J_1P_{in}');
title('PHD Error with \phi_{mx}=3\pi/4')

%% function
function F = Frefl(theta,R)
F = sqrt(R)*(1 - exp(1i*theta))./(1 - R*exp(1i*theta));
end