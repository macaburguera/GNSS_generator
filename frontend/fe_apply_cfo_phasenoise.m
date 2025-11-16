
function x = fe_apply_cfo_phasenoise(x, Fs, cfg)
%FE_APPLY_CFO_PHASENOISE Add CFO and phase noise / wander.
% cfg fields:
%   .cfo_hz            : carrier freq offset (Hz)
%   .pn_wn_std_deg     : white phase noise per-sample std (deg)
%   .pn_rw_std_deg     : random-walk phase std per sqrt(s) (deg/sqrt(s))
%   .fm_wander_hz      : slow FM wander amplitude (Hz)
%   .fm_wander_rate_hz : slow FM wander 3dB rate (Hz), sinusoidal
    N = numel(x);
    n = (0:N-1).';
    phi = zeros(N,1);
    if isfield(cfg,'pn_wn_std_deg') && cfg.pn_wn_std_deg>0
        phi = phi + deg2rad(cfg.pn_wn_std_deg)*randn(N,1);
    end
    if isfield(cfg,'pn_rw_std_deg') && cfg.pn_rw_std_deg>0
        % random-walk phase: integrate white noise
        phi = phi + cumsum(deg2rad(cfg.pn_rw_std_deg)*randn(N,1)/sqrt(Fs));
    end
    fm = 0;
    if isfield(cfg,'fm_wander_hz') && cfg.fm_wander_hz>0
        fr = 0.1; % default slow rate
        if isfield(cfg,'fm_wander_rate_hz') && cfg.fm_wander_rate_hz>0
            fr = cfg.fm_wander_rate_hz;
        end
        fm = cfg.fm_wander_hz * sin(2*pi*fr*n/Fs);
    end
    cfo = 0;
    if isfield(cfg,'cfo_hz'), cfo = cfg.cfo_hz; end
    instf = (cfo + fm)/Fs; % cycles per sample
    ph = 2*pi*cumsum(instf) + phi;
    x = x .* exp(1j*ph);
end
