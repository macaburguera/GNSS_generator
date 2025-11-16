
function x = fe_apply_spurs(x, Fs, cfg)
%FE_APPLY_SPURS Inject LO leakage/DC and a comb of fractional-N spurs.
% cfg fields:
%   .lo_leak_dbfs   : LO tone level (dBFS)
%   .comb_dbfs      : vector of spur dBFS (length K)
%   .comb_offset_hz : vector of offsets from DC (Hz), length K (can be +/-)
%   .am_jitter_db   : dB variation per spur (std), applied per block
    N = numel(x);
    n = (0:N-1).';
    y = x;
    if isfield(cfg,'lo_leak_dbfs') && ~isempty(cfg.lo_leak_dbfs)
        A = 10^(cfg.lo_leak_dbfs/20); % dBFS
        y = y + A*ones(N,1);
    end
    if isfield(cfg,'comb_dbfs') && ~isempty(cfg.comb_dbfs) ...
            && isfield(cfg,'comb_offset_hz') && ~isempty(cfg.comb_offset_hz)
        K = min(numel(cfg.comb_dbfs), numel(cfg.comb_offset_hz));
        for k=1:K
            Ak = 10^(cfg.comb_dbfs(k)/20);
            fk = cfg.comb_offset_hz(k);
            if isfield(cfg,'am_jitter_db') && cfg.am_jitter_db>0
                Ak = Ak * 10.^(randn*cfg.am_jitter_db/20);
            end
            y = y + Ak*exp(1j*2*pi*fk*n/Fs);
        end
    end
    x = y;
end
