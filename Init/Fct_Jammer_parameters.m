function ParamJam = Fct_Jammer_parameters(Fs)
% Canonical jammer classes aligned with Jammertest (plus NoJam baseline)
% Backwards-compatible with your original structure and augmented with a
% 'helpers' section used by the new generator. Fs defaults to 60 MHz.

if nargin < 1 || isempty(Fs)
    Fs = 60e6;
end

ParamJam = struct();
ParamJam.Fs = Fs;

% ---- Canonical classes / bands (legacy kept verbatim) --------------------
ParamJam.class_set = {'NoJam','Chirp','NB','CW','WB','FH'};

ParamJam.allowed_bands = {'L1','L2','L5','E1','E5a','G1'};
ParamJam.tone_offset_defaults = struct('L1',0,'L2',0,'L5',0,'E1',0,'E5a',0,'G1',0);

% ---- Chirp / Sweep (legacy fields) --------------------------------------
ParamJam.chirp.period_us = [5, 60];         % sweep period
ParamJam.chirp.bw_MHz    = [20, 80];        % sweep bandwidth
ParamJam.chirp.wave      = 'sawtooth';      % sweep shape
ParamJam.chirp.edge_win  = 0.02;            % taper on/off edges (fraction)

% ---- NB PRN (~1 MHz) ----------------------------------------------------
ParamJam.nb.chip_rate_Hz  = [0.8e6, 1.2e6];
ParamJam.nb.rolloff       = 0.35;
ParamJam.nb.osc_offset_Hz = [8.7e6, 9.3e6];  % we multiply by ±1 in the generator

% ---- WB PRN (~10 MHz) ---------------------------------------------------
ParamJam.wb.chip_rate_Hz  = [8e6, 12e6];
ParamJam.wb.rolloff       = 0.25;
ParamJam.wb.osc_offset_Hz = [-5e6, +5e6];

% ---- CW -----------------------------------------------------------------
ParamJam.cw.tone_offset_Hz = [-10e6, +10e6];

% ---- Frequency Hopping (defaults — may be refined elsewhere) ------------
ParamJam.fh.num_tones        = 6;
ParamJam.fh.step_Hz          = 200e3;
ParamJam.fh.dwell_s          = 0.050;
ParamJam.fh.start_offset_Hz  = [-600e3, -300e3];
ParamJam.fh.phase_continuous = true;

% ---- Dataset prior (legacy) ---------------------------------------------
% order:  NoJam  Chirp   NB     CW     WB     FH
ParamJam.target_classes_prob = [0.25,  0.35,  0.10,  0.10,  0.15,  0.05];

% one-band-per-sample policy (legacy, keep as-is)
ParamJam.per_sample_bands = 'random_one';

% ========================================================================
% Augmented helpers (used by the updated generator but harmless elsewhere)
% ========================================================================
helpers = struct();

% Jammertest-like C/N0 and JSR ranges (tunable)
helpers.CNR_dBHz_rng = [30 70];     % realistic GNSS C/N0
helpers.JSR_dB_rng   = [0 60];    % jammer-to-signal ratio (in-band)

% Bursting: duty randomly in [0.35..1]; gate length ~ sample length
helpers.burst = @() struct('duty', 0.35 + 0.65*rand(), 'len', []);

% Slow frequency wander model parameters for CW/NB etc.
helpers.wander = @() struct('sigma', 2 + 18*rand(), 'fcorner', 10 + 60*rand());

% Store helpers
ParamJam.helpers = helpers;
end
