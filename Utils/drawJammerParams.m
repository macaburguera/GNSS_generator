function jp = drawJammerParams(jamCode, ParamSim)
% Generate reasonable per-sample jammer parameters (independent of JSR/CNR).
% Only recorded in meta unless your Fct_Jammer_gen uses these fields.
Ts = ParamSim.Nc * 1e-3;                % coherent window (s)
% Helper draws
unif = @(a,b) (a + (b-a)*rand());
posint = @(a,b) (a + floor((b-a+1)*rand())); % integer in [a,b]
jp = struct();
switch jamCode
    case 1 % NoJam
        % nothing
    case 2 % SingleAM: tone AM on a carrier
        jp.AM_tone_Hz   = unif(100, 5e3);    % 0.1–5 kHz
        jp.AM_mod_index = unif(0.1, 0.9);    % modulation depth
    case 5 % SingleFM: narrowband FM
        jp.FM_mod_Hz    = unif(100, 5e3);    % 0.1–5 kHz
        jp.FM_dev_Hz    = unif(1e3, 5e4);    % 1–50 kHz deviation
    case 10 % NB: 1–3 tones with spacing/drift
        jp.NB_num_tones      = posint(1,3);
        jp.NB_spacing_Hz     = unif(5e5, 2e6);   % 0.5–2 MHz spacing
        jp.NB_base_offset_Hz = unif(-1e5, 1e5);  % ±100 kHz drift
    case 3 % SingleChirp: up/down, various BW and slope
        BW = unif(1e6, 20e6);                  % 1–20 MHz across window
        dir = sign(unif(-1,1)); if dir==0, dir=1; end
        slope = dir * (BW / max(Ts,1e-6));     % Hz/s over window
        jp.Chirp_BW_Hz      = BW;
        jp.Chirp_direction  = dir;             % +1 up / -1 down
        jp.Chirp_slope_HzPs = slope;
    case 9 % DME-like pulsed
        % Typical DME-X around 12 μs PRI multiples; jitter and 3–6 μs pulse width
        basePRI = unif(10e-6, 80e-6);          % 10–80 μs
        jp.DME_PRI_s     = basePRI;
        jp.DME_pw_s      = unif(2e-6, 8e-6);   % 2–8 μs
        jp.DME_jitter_s  = unif(0, 0.2*basePRI);
    otherwise
        % leave empty
end
end
