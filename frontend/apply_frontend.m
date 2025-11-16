function x = apply_frontend(x, fs, FE)
% Apply realistic RX (or emitter) front-end effects.
% Fields (all optional):
%   FE.enable (bool)
%   FE.dc_offset (complex)
%   FE.iq_gain_imbalance_dB
%   FE.iq_phase_deg
%   FE.amp_flicker_dB
%   FE.spurs.enable, .count, .rel_dB, .bw_Hz=[fmin fmax]
%   FE.phase_noise.L_dBc_Hz, .f0_Hz
%   FE.softclip_dBFS

if ~isstruct(FE) || ~getdef(FE,'enable',false)
    return;
end

N = numel(x); t = (0:N-1).'/fs;

% DC offset
dc = getdef(FE,'dc_offset',0);
if ~isempty(dc) && any(dc~=0), x = x + complex(dc); end

% IQ imbalance
g_dB = getdef(FE,'iq_gain_imbalance_dB',0);
ph   = getdef(FE,'iq_phase_deg',0);
if g_dB~=0 || ph~=0
    g  = 10^(g_dB/20);
    th = ph*pi/180;
    xr = real(x); xi = imag(x);
    Ir = g.*xr;
    Qi = xi*cos(th) + xr*sin(th);
    x  = complex(Ir, Qi);
end

% Slow AM ripple
Aflk = getdef(FE,'amp_flicker_dB',0);
if Aflk>0
    m   = 10^(Aflk/20);
    f0  = 40 + 80*rand();        % 40–120 Hz
    env = 1 + (m-1)*sin(2*pi*f0*t + 2*pi*rand());
    x   = x .* env;
end

% Phase noise (very light)
PN = getdef(FE,'phase_noise',struct());
if isstruct(PN) && isfield(PN,'L_dBc_Hz') && isfield(PN,'f0_Hz')
    L1k = PN.L_dBc_Hz;  fcorner = max(1, PN.f0_Hz);
    S_phi = 2*10^(L1k/10);
    sigma = sqrt(S_phi*fs/max(fcorner,1)) * 1e-4;
    dphi  = sigma*randn(N,1);
    phi   = cumsum(dphi);
    x     = x .* exp(1j*phi);
end

% Spurs (small)
SP = getdef(FE,'spurs',struct('enable',false));
if isstruct(SP) && getdef(SP,'enable',false)
    M   = max(1, getdef(SP,'count',2));
    rel = getdef(SP,'rel_dB',-28);  g = 10^(rel/20);
    BW  = getdef(SP,'bw_Hz',[0.2e6, 1.0e6]);
    for m=1:M
        bwm = BW(1) + (BW(2)-BW(1))*rand();
        per = (6e-6 + 10e-6*rand());
        s   = exp(1j*2*pi*cumsum( (-bwm/2) + bwm*( (0:N-1)'/(per*fs) - floor((0:N-1)'/(per*fs)) ) )/fs);
        x   = x + g*s .* exp(1j*2*pi*rand());
    end
end

% Soft clip / limiter
dBFS = getdef(FE,'softclip_dBFS',[]);
if ~isempty(dBFS)
    a = 10^(dBFS/20);
    mag = abs(x);
    x = x .* (tanh(mag/a) ./ max(mag, eps));
end
end

function v = getdef(S, name, def)
if isstruct(S) && isfield(S,name) && ~isempty(S.(name)), v = S.(name); else, v = def; end
end
