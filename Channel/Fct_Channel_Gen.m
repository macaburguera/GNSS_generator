function [y, meta] = Fct_Channel_Gen(~, ParamGNSS, Pjam, Fs, Ns, band, CNo_dBHz, JSR_dB)
%FCT_CHANNEL_GEN  GNSS + Jammer + AWGN + realistic RX front-end (Fs=60 MHz).
% Keeps your calling signature used in signal_generation_jammertest.m

% ---- GNSS baseline (unit power) ----
SVN = max(6, getfield_def(ParamGNSS,'SV_Number',8));
x_gnss = gen_gnss_like(Ns, Fs, SVN);      % ~unit power

% ---- Noise for requested C/N0 (dB-Hz) ----
% If signal power = 1, N0 = 1 / 10^(C/N0/10). Complex AWGN variance = N0*Fs.
N0 = 1 / (10^(CNo_dBHz/10));
sigma2 = N0 * Fs;
w = sqrt(sigma2/2) * (randn(Ns,1) + 1j*randn(Ns,1));

% ---- Jammer waveform (unit power out of factory) ----
Pj = Pjam; if ~isfield(Pj,'type'), Pj.type = 'NoJam'; end
x_jam = jammer_factory(Pj, Fs, Ns);   % unit power by construction

% ---- Scale jammer to meet JSR (in-band approximation) ----
if ~isnan(JSR_dB)
    p_jam_target = 10^(JSR_dB/10);   % since GNSS power ~1
    x_jam = x_jam * sqrt(p_jam_target + eps);
else
    x_jam = zeros(Ns,1);
end

% ---- Mix pre-front-end ----
x_mix = x_gnss + x_jam + w;

% ---- Receiver/RF Front-end (applied to ALL classes -> realistic NoJam) ----
FE = make_frontend_params(Fs);      % random but bounded
y  = apply_frontend(x_mix, Fs, FE);

% ---- Meta ----
meta = struct();
meta.band        = band;
meta.SV_Number   = SVN;
meta.CNo_dBHz    = CNo_dBHz;
meta.JSR_dB      = JSR_dB;
meta.frontend    = FE;
meta.jammer_P    = Pjam;
meta.pow = struct( ...
    'gnss', mean(abs(x_gnss).^2), ...
    'jam',  mean(abs(x_jam ).^2), ...
    'nois', mean(abs(w     ).^2), ...
    'out',  mean(abs(y     ).^2));
end

% ================= helpers =================
function x = gen_gnss_like(N, Fs, K)
% Sum of K BPSK(C/A-like) channels with small Dopplers -> noise-like
chip = 1.023e6;
t = (0:N-1).' / Fs;
x = complex(zeros(N,1));
for k = 1:K
    doppler = (rand()*2-1) * 5e3;   % +/- 5 kHz
    prnlen  = 1023;
    code = 2*(randi([0 1], prnlen, 1))-1;
    chips_per_samp = chip / Fs;
    chip_idx = floor((0:N-1).'*chips_per_samp) + 1;
    chip_idx = 1 + mod(chip_idx-1, prnlen);
    sig = code(chip_idx);
    x = x + sig .* exp(1j*2*pi*doppler*t) .* exp(1j*2*pi*rand());
end
x = x / sqrt(mean(abs(x).^2) + 1e-12);
end

function v = getfield_def(S, name, def)
if isstruct(S) && isfield(S, name), v = S.(name); else, v = def; end
end
