
function x = fe_apply_agc_adc(x, cfg)
%FE_APPLY_AGC_ADC Apply slow AGC, clipping, and quantization.
% cfg fields:
%   .agc_target_rms   : target RMS (e.g., 0.2)
%   .agc_bw_hz        : 3dB bandwidth of AGC detector (e.g., 50 Hz)
%   .fs               : sampling rate
%   .clip_limit       : full-scale limit (1.0 => +/-1)
%   .clip_knee        : knee for softclip
%   .bits             : ADC bits (e.g., 8)
    if ~isfield(cfg,'agc_target_rms'), cfg.agc_target_rms = 0.2; end
    if ~isfield(cfg,'agc_bw_hz'), cfg.agc_bw_hz = 50; end
    if ~isfield(cfg,'fs'), error('cfg.fs required'); end
    if ~isfield(cfg,'clip_limit'), cfg.clip_limit = 1.0; end
    if ~isfield(cfg,'clip_knee'), cfg.clip_knee = 0.1; end
    if ~isfield(cfg,'bits'), cfg.bits = 8; end

    N = numel(x);
    % Envelope detector (IIR 1st order)
    alpha = math_exp(-2*pi*cfg.agc_bw_hz/cfg.fs);
    env = zeros(N,1);
    g = ones(N,1);
    y = zeros(N,1);
    for n=1:N
        env(n) = (1-alpha)*abs(x(n)) + alpha*(n>1)*env(max(n-1,1));
        if env(n) > 0
            g(n) = cfg.agc_target_rms / env(n);
        else
            g(n) = 1;
        end
        y(n) = x(n) * g(n);
    end
    % Soft clip
    y = softclip(y, cfg.clip_limit, cfg.clip_knee);
    % Uniform quantization
    L = 2^cfg.bits;
    q = 2*cfg.clip_limit / (L-1);
    yq = round((real(y)+cfg.clip_limit)/q)*q - cfg.clip_limit ...
       + 1j*(round((imag(y)+cfg.clip_limit)/q)*q - cfg.clip_limit);
    x = yq;
end

function y = math_exp(a)
% helper for compatibility with MATLAB codegen
    y = exp(a);
end
