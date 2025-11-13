%% signal_generation_jammertest.m
% Build a stratified dataset (TRAIN/VAL/TEST) with exact per-class quotas.

clear; clc;
addpath(genpath('Init')); addpath(genpath('Utils'));
addpath(genpath('Jammer_signals')); addpath(genpath('Channel'));
addpath(genpath('GNSS_signals'));

%% ---------------- USER CONFIG ----------------
OutRoot   = fullfile(pwd,'datasets_jammertest');
Seed      = 42;

% ----- JAMMERTEST tile length (matches real spectrogram tiles) -----
Fs = 62.5e6;      % Hz
Ns = 2048;        % samples  --> 32.768 µs @ 62.5 MHz

% Use at least six satellites; generator should honor this
ParamGNSS = struct('SV_Number', 8);

% Available GNSS bands to randomize per sample
Bands     = {'L1CA','L2C','L5','E1OS'};

% Classes (including NoJam)
Classes   = {'NoJam','Chirp','NB','CW','WB','FH'};

% Splits
Splits    = {'TRAIN','VAL','TEST'};

% --- Choose ONE of these "Counts" styles ---
% (A) Uniform counts per class
Counts.TRAIN = 3000;
Counts.VAL   = 1000;
Counts.TEST  = 1000;

% Stratified C/N0 (dB-Hz) and JSR (dB) bins (uniform within bins)
CNo_bins = [30 35 40 45 50 60];
JSR_bins = [0 10 15 20 25 30 35 40 45 50 60]; % add 60 if you want “angry” NB

% (Optional) Chirp “families” ranges (kept for future; not strictly needed now)
ChirpFamilies = struct( ...
  'U', struct('period_us',[5 8],  'bw_MHz',[70 80]), ...
  'S', struct('period_us',[20 60],'bw_MHz',[25 35]), ...
  'H', struct('period_us',[6 10], 'bw_MHz',[18 24]) ...
);

%% ---------------------------------------------
rng(Seed);

% enforce >=6 SVs
if ~isfield(ParamGNSS,'SV_Number') || ParamGNSS.SV_Number < 6
    ParamGNSS.SV_Number = 6;
end

% Expand per-split/per-class quotas from Counts into Quota.SPLIT.CLASS
Quota = expandCounts(Counts, Splits, Classes);

% Default jammer parameter ranges
ParamJamDef = Fct_Jammer_parameters();

% Output root
if ~exist(OutRoot,'dir'); mkdir(OutRoot); end
fprintf('Output root: %s\n', OutRoot);
fprintf('Splits: %s | Classes: %s\n', strjoin(Splits,','), strjoin(Classes,','));
dt_us = 1e6 * Ns / Fs;
fprintf('SV_Number: %d | Fs=%.2f MHz | Ns=%d (%.3f µs)\n', ...
    ParamGNSS.SV_Number, Fs/1e6, Ns, dt_us);

for s = 1:numel(Splits)
    split = Splits{s};
    out_dir_split = fullfile(OutRoot, split);
    if ~exist(out_dir_split,'dir'); mkdir(out_dir_split); end
    fprintf('\n--- Generating %s ---\n', split);

    for ci = 1:numel(Classes)
        cls = Classes{ci};
        tgtN = Quota.(split).(cls);

        out_dir_cls = fullfile(out_dir_split, cls);
        if ~exist(out_dir_cls,'dir'); mkdir(out_dir_cls); end
        fprintf('  Class %-6s : %d samples\n', cls, tgtN);

        for n = 1:tgtN
            % Deterministic but shuffled seed per (split,class,n)
            rng(Seed + s*100000 + ci*1000 + n);

            band = Bands{ randi(numel(Bands)) };

            cno = draw_in_bins(CNo_bins);
            if strcmpi(cls,'NoJam'), jsr = NaN; else, jsr = draw_in_bins(JSR_bins); end

            % Build jammer parameters for this sample
            Pjam = build_jammer_params(cls, band, ParamJamDef, ChirpFamilies);

            % ---- Synthesize ----
            [y, meta] = Fct_Channel_Gen([], ParamGNSS, Pjam, Fs, Ns, band, cno, jsr);

            % ---- Meta ----
            if isfield(meta,'CNo_dBHz'); meta.CNR_dBHz = meta.CNo_dBHz; end
            meta.band   = band;
            meta.jam_name = cls;
            meta.jam_code = cls;
            meta.seed     = randi(2^31-1);
            meta.fs_Hz    = Fs;
            meta.N        = Ns;
            meta.dt_s     = Ns / Fs;

            % ---- Save ----
            GNSS_plus_Jammer_awgn = y(:); %#ok<NASGU>
            fn = sprintf('%s_%s_%06d.mat', split, cls, n);
            save(fullfile(out_dir_cls, fn), 'GNSS_plus_Jammer_awgn', 'meta', '-v7.3');

            if mod(n, max(1, floor(tgtN/10)))==0
                fprintf('    [%s] %s %4d/%4d\n', split, cls, n, tgtN);
            end
        end
    end
end

fprintf('\nDone. Root: %s\n', OutRoot);

%% =============== LOCAL HELPERS (in-script) ===============
function Quota = expandCounts(CountsSpec, Splits, Classes)
    for s = 1:numel(Splits)
        sp = Splits{s};
        if ~isfield(CountsSpec, sp), error('Counts.%s missing', sp); end
        spec = CountsSpec.(sp);

        if isnumeric(spec) && isscalar(spec)
            for c = 1:numel(Classes), Quota.(sp).(Classes{c}) = round(spec); end
        elseif isnumeric(spec) && isvector(spec) && numel(spec) == numel(Classes)
            for c = 1:numel(Classes), Quota.(sp).(Classes{c}) = round(spec(c)); end
        elseif isstruct(spec)
            for c = 1:numel(Classes)
                cls = Classes{c};
                if ~isfield(spec, cls), error('Counts.%s.%s missing', sp, cls); end
                Quota.(sp).(cls) = round(spec.(cls));
            end
        else
            error('Counts.%s must be scalar, vector(numClasses), or struct with class fields.', sp);
        end
    end
end

function val = draw_in_bins(edges)
    k = randi(numel(edges)-1);
    a = edges(k); b = edges(k+1);
    val = a + (b-a)*rand();
end

function v = pick_in(rng2)
    v = rng2(1) + diff(rng2)*rand();
end

function P = build_jammer_params(cls, bandTok, Def, ~)
    % Device-like families so labels cover Jammertest variants.
    pick   = @(ab) ab(1) + (ab(2)-ab(1))*rand();
    choose = @(C) C{randi(numel(C))};
    RF.L1 = 1575.42e6; RF.G1 = 1602.0e6; RF.L2 = 1227.60e6; RF.L5 = 1176.45e6; RF.E6 = 1278.75e6;

    switch cls
        case 'NoJam'
            P = struct('type','NoJam');

        case 'Chirp'
            fam = choose({'USB','CigS1','CigS2','NEAT','H3_3','H4_1'});
            base = struct('type','Chirp', 'shape', choose({'sawup','sawdown','tri'}), ...
                          'edge_win', Def.chirp.edge_win, 'osc_offset_Hz', 0);
            switch fam
                case 'USB'     % U1.1–U1.4
                    base.bw_Hz     = pick([70, 80])*1e6;
                    base.period_s  = pick([5, 8])*1e-6;
                    base.rf_Hz     = pick([1580, 1595])*1e6; % L1/E1 flank
                    P = base;
                case 'CigS1'   % S1.1–S1.3 (L1)
                    base.bw_Hz     = 30e6;
                    base.period_s  = pick([20, 40])*1e-6;
                    base.rf_Hz     = RF.L1; P = base;
                case 'CigS2'   % S2.1–S2.4 (L1+L2 dual)
                    cL1 = base; cL1.bw_Hz=30e6; cL1.period_s=pick([20,60])*1e-6; cL1.rf_Hz=RF.L1;
                    cL2 = cL1;  cL2.rf_Hz = RF.L2;
                    P = struct('type','Composite','components',{{cL1,cL2}},'weights',[1,1]);
                case 'NEAT'    % H1.1 (≈20–24 MHz, 10 µs)
                    base.bw_Hz     = pick([18, 24])*1e6; base.period_s  = 10e-6;
                    base.rf_Hz     = choose({RF.L1, RF.L2}); P = base;
                case 'H3_3'    % 3-band handheld, 13 µs
                    c1 = base; c1.period_s=13e-6; c1.bw_Hz=20e6; c1.rf_Hz=RF.L1;
                    c2 = base; c2.period_s=13e-6; c2.bw_Hz=14e6; c2.rf_Hz=RF.L2;
                    c3 = base; c3.period_s=13e-6; c3.bw_Hz=17e6; c3.rf_Hz=RF.L5;
                    P  = struct('type','Composite','components',{{c1,c2,c3}},'weights',[1,1,1], ...
                                'spurs',struct('enable',true,'count',randi([2,6]), ...
                                               'rel_dB',-20-20*rand(),'bw_Hz',[0.5e6, 5e6]));
                case 'H4_1'    % 4-band handheld (L1 wide, E6 wide)
                    c1 = base; c1.period_s=9e-6;  c1.bw_Hz=100e6; c1.rf_Hz=1550e6;
                    cE = base; cE.period_s=9e-6;  cE.bw_Hz=45e6;  cE.rf_Hz=1260e6;
                    c2 = base; c2.period_s=9e-6;  c2.bw_Hz=20e6;  c2.rf_Hz=1220e6;
                    c5 = base; c5.period_s=9e-6;  c5.bw_Hz=20e6;  c5.rf_Hz=1182e6;
                    P  = struct('type','Composite','components',{{c1,cE,c2,c5}},'weights',[1,1,1,1]);
            end

        case 'NB'
            fam = choose({'NEAT_NB','RealPRN9M_subsample'});
            switch fam
                case 'NEAT_NB'
                    P = struct('type','PRN', 'rate_Hz', pick([0.8,1.2])*1e6, ...
                               'rolloff', 0.2, 'filter','rrc', ...
                               'osc_offset_Hz', pick(Def.nb.osc_offset_Hz), ...
                               'rf_Hz', choose({RF.L1,RF.L2}));
                case 'RealPRN9M_subsample'
                    P = struct('type','PRN', 'rate_Hz', 9e6, ...
                               'rolloff', 0.0, 'filter','rect', 'periodicity_s', 1e-3, ...
                               'downsample_like_NB', true, ...
                               'osc_offset_Hz', pick(Def.nb.osc_offset_Hz), ...
                               'rf_Hz', RF.L1);
            end

        case 'WB'
            fam = choose({'NEAT_WB','RealPRN9M_clean'});
            switch fam
                case 'NEAT_WB'
                    P = struct('type','PRN', 'rate_Hz', pick([8,12])*1e6, ...
                               'rolloff', 0.2, 'filter','rrc', ...
                               'osc_offset_Hz', pick(Def.wb.osc_offset_Hz), ...
                               'rf_Hz', choose({RF.L1,RF.L2}));
                case 'RealPRN9M_clean'
                    P = struct('type','PRN', 'rate_Hz', 9e6, ...
                               'rolloff', 0.0, 'filter','rect', 'periodicity_s', 1e-3, ...
                               'osc_offset_Hz', pick(Def.wb.osc_offset_Hz), ...
                               'rf_Hz', choose({RF.L1,RF.G1,RF.L2,RF.L5}));
            end

        case 'CW'
            if rand()<0.5
                P = struct('type','CW','tone_offset_Hz', pick([-1,1])*pick([0, 150e3]), ...
                           'freq_drift_Hzps', pick([-200,200]), 'amp_flicker_dB', pick([0,1.5]), ...
                           'rf_Hz', choose({RF.L1,RF.L2}));
            else
                K = randi([2,5]);
                offs = linspace(-pick([3,10])*1e6, pick([3,10])*1e6, K) + 1e3*randn(1,K);
                P = struct('type','CWcomb','offsets_Hz', offs, 'rf_Hz', RF.L1);
            end

        case 'FH'
            P = struct('type','FH', ...
                       'num_tones', randi([3,8]), ...
                       'step_Hz', pick([0.5, 5])*1e6, ...
                       'dwell_s', pick([5, 100])*1e-6, ...
                       'phase_continuous', rand()<0.5, ...
                       'rf_Hz', choose({RF.L1,RF.L2,RF.L5}));

        otherwise
            error('Unknown class "%s"', cls);
    end

    if ~strcmp(cls,'NoJam') && ~isfield(P,'osc_offset_Hz')
        P.osc_offset_Hz = pick([-0.5, 0.5])*1e6;
    end
end
