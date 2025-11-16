
function x = fe_apply_dc_iq(x, cfg)
%FE_APPLY_DC_IQ Apply DC offsets and IQ imbalance (gain/phase).
% cfg fields:
%   .dcI, .dcQ         : DC in linear (0..0.2 typ)
%   .iq_gain_imb_db    : dB difference between I and Q (e.g., 0.2 dB)
%   .iq_phase_deg      : phase mismatch in degrees (e.g., 1 deg)
    if ~isfield(cfg,'dcI'), cfg.dcI = 0; end
    if ~isfield(cfg,'dcQ'), cfg.dcQ = 0; end
    if ~isfield(cfg,'iq_gain_imb_db'), cfg.iq_gain_imb_db = 0; end
    if ~isfield(cfg,'iq_phase_deg'), cfg.iq_phase_deg = 0; end
    I = real(x) + cfg.dcI;
    Q = imag(x) + cfg.dcQ;
    g = 10^(cfg.iq_gain_imb_db/20);
    phi = deg2rad(cfg.iq_phase_deg);
    % Apply gain to I, a small rotation for Q
    I = g*I;
    Qr =  cos(phi)*Q + sin(phi)*I;
    x = complex(I, Qr);
end
