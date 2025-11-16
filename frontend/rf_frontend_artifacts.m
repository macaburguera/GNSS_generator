
function x = rf_frontend_artifacts(x, Fs, className, cfg)
%RF_FRONTEND_ARTIFACTS Apply a cascade of realistic front-end impairments.
% className is used to slightly vary defaults per class ('NoJam','NB','CW','WB','Chirp','FH')
% cfg allows overriding any nested field.
%
% Order:
%   DC/IQ -> BPF ripple -> CFO/PhaseNoise -> Spurs -> AGC/ADC -> Colored Noise
%
% Defaults chosen to be modest; NoJam gets a tad higher spur/leakage to emulate "quiet band" issues.
    if nargin < 3 || isempty(className), className = 'NoJam'; end
    if nargin < 4, cfg = struct(); end
    % --- defaults by class
    base = struct();
    switch className
        case 'NoJam'
            base.dcI = 0.01; base.dcQ = 0.005;
            base.iq_gain_imb_db = 0.2; base.iq_phase_deg = 1.0;
            base.cfo_hz = 50; base.pn_wn_std_deg = 0.05; base.pn_rw_std_deg = 0.5;
            base.fm_wander_hz = 2; base.fm_wander_rate_hz = 0.2;
            base.lo_leak_dbfs = -40;
            base.comb_dbfs = [-55 -58 -60]; base.comb_offset_hz = [200e3, -350e3, 600e3]; base.am_jitter_db = 0.5;
            base.BpHz = 8e6; base.RippleDb = 0.8; base.TiltDb = 0.3; base.Ntaps = 257;
            base.agc_target_rms = 0.18; base.agc_bw_hz = 30; base.clip_limit = 1.0; base.clip_knee = 0.12; base.bits = 8;
            base.SNR_dB = 32; base.pink_ratio = 0.25;
        otherwise
            base.dcI = 0.006; base.dcQ = 0.003;
            base.iq_gain_imb_db = 0.15; base.iq_phase_deg = 0.7;
            base.cfo_hz = 30; base.pn_wn_std_deg = 0.04; base.pn_rw_std_deg = 0.35;
            base.fm_wander_hz = 1; base.fm_wander_rate_hz = 0.15;
            base.lo_leak_dbfs = -46;
            base.comb_dbfs = [-60 -62]; base.comb_offset_hz = [250e3, -500e3]; base.am_jitter_db = 0.5;
            base.BpHz = 8e6; base.RippleDb = 0.6; base.TiltDb = 0.2; base.Ntaps = 257;
            base.agc_target_rms = 0.2; base.agc_bw_hz = 40; base.clip_limit = 1.0; base.clip_knee = 0.1; base.bits = 8;
            base.SNR_dB = 34; base.pink_ratio = 0.2;
    end
    % merge user cfg into base
    f = fieldnames(cfg);
    for i=1:numel(f)
        base.(f{i}) = cfg.(f{i});
    end
    % Apply in cascade
    x = fe_apply_dc_iq(x, base);
    x = fe_apply_bpf_ripple(x, Fs, base);
    x = fe_apply_cfo_phasenoise(x, Fs, base);
    x = fe_apply_spurs(x, Fs, base);
    agc = base; agc.fs = Fs;
    x = fe_apply_agc_adc(x, agc);
    x = fe_apply_colored_noise(x, Fs, base);
end
