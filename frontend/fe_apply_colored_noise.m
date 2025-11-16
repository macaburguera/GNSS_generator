
function x = fe_apply_colored_noise(x, Fs, cfg)
%FE_APPLY_COLORED_NOISE Add thermal + colored noise to emulate LNA/mixer flicker.
% cfg fields:
%   .SNR_dB        : desired SNR w.r.t. current RMS power of x (dB)
%   .pink_ratio    : 0..1 fraction of pink (1/f) vs white
%   .oob_leak_db   : level of OOB leakage relative to inband noise (dB)
    if ~isfield(cfg,'SNR_dB'), cfg.SNR_dB = 30; end
    if ~isfield(cfg,'pink_ratio'), cfg.pink_ratio = 0.2; end
    N = numel(x);
    % white
    nw = randn(N,1) + 1j*randn(N,1);
    % pink-ish
    np = pinknoise(N) + 1j*pinknoise(N);
    n = (1-cfg.pink_ratio)*nw + (cfg.pink_ratio)*np;
    % scale to target SNR vs signal RMS
    Px = mean(abs(x).^2);
    Pn = mean(abs(n).^2);
    targetPn = Px / db2lin(cfg.SNR_dB);
    n = n * sqrt(targetPn / max(Pn, eps));
    x = x + n;
end
