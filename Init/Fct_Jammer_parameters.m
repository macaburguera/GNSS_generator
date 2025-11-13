function ParamJam = Fct_Jammer_parameters()
% Canonical jammer classes aligned with Jammertest (plus NoJam baseline)

ParamJam.class_set = {'NoJam','Chirp','NB','CW','WB','FH'};

ParamJam.allowed_bands = {'L1','L2','L5','E1','E5a','G1'};
ParamJam.tone_offset_defaults = struct('L1',0,'L2',0,'L5',0,'E1',0,'E5a',0,'G1',0);

% ---- Chirp/Sweep
ParamJam.chirp.period_us = [5, 60];
ParamJam.chirp.bw_MHz    = [20, 80];
ParamJam.chirp.wave      = 'sawtooth';
ParamJam.chirp.edge_win  = 0.02;

% ---- NB PRN (~1 MHz)
ParamJam.nb.chip_rate_Hz  = [0.8e6, 1.2e6];
ParamJam.nb.rolloff       = 0.35;
ParamJam.nb.osc_offset_Hz = [-0.8e6, +0.8e6];

% ---- WB PRN (~10 MHz)
ParamJam.wb.chip_rate_Hz  = [8e6, 12e6];
ParamJam.wb.rolloff       = 0.25;
ParamJam.wb.osc_offset_Hz = [-5e6, +5e6];

% ---- CW
ParamJam.cw.tone_offset_Hz = [-10e6, +10e6];

% ---- Frequency Hopping (defaults — overwritten by build_jammer_params)
ParamJam.fh.num_tones        = 6;
ParamJam.fh.step_Hz          = 200e3;
ParamJam.fh.dwell_s          = 0.050;
ParamJam.fh.start_offset_Hz  = [-600e3, -300e3];
ParamJam.fh.phase_continuous = true;

% ---- Dataset prior (you can tune)
% order:  NoJam  Chirp  NB   CW   WB   FH
ParamJam.target_classes_prob = [0.25, 0.35, 0.10, 0.10, 0.15, 0.05];

ParamJam.per_sample_bands = 'random_one';
end
