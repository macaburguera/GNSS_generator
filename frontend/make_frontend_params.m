function fe = make_frontend_params(Fs)
% Randomize realistic front-end artifacts (applied to ALL classes)
fe = struct();
fe.Fs = Fs;

% DC feedthrough (dBc relative to RMS after mix)
fe.dc_dbc = -45 + rand()*20;      % -45 .. -25 dBc
% IQ imbalance
fe.iq_gain_dB  = (randn()*0.6);   % ±0.6 dB
fe.iq_phase_deg= (randn()*2.0);   % ±2 deg
% Phase noise (random walk std in degrees over 1 ms)
fe.phasenoise_deg_per_ms = 2.0 + 10.0*rand();  % 2..12 deg/ms eqv.
% Weak clock error -> slight resampling (ppm)
fe.clock_ppm = (randn()*0.3);     % ~±0.3 ppm
% AGC ripple
fe.agc_tau_ms = 0.2 + 1.5*rand(); % 0.2..1.7 ms time constant
fe.agc_target_rms = 0.9 + 0.4*rand(); % 0.9..1.3
% PA non-linearity (soft clip level)
fe.softclip_lvl = 2.0 + 1.5*rand();  % ~2..3.5 (relative to post-AGC RMS)
% Front-end band-shape (IF SAW etc.)
fe.rf_bw_Hz   = 24e6 + rand()*10e6;  % 24..34 MHz
fe.rf_ripple_dB = 0.5 + 2.0*rand();  % 0.5..2.5 dB
% Quantization (effective bits)
fe.q_bits = 6 + randi(2);           % 6..8 ENOB
% Small idle spur (helps NoJam look real)
fe.idle_spur_dbc = -55 + rand()*12; % -55..-43 dBc
end
