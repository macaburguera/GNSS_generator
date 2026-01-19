%% signal_generation_jammertest.m
% Build a stratified dataset (TRAIN/VAL/TEST) with exact per-class quotas.
% Preserves your original structure + families. Fs fixed to 60 MHz.
% Adds realistic receiver front-end (applied to ALL, so NoJam becomes realistic).

clear; clc;
addpath(genpath('Init')); addpath(genpath('Utils'));
addpath(genpath('Jammer_signals')); addpath(genpath('Channel'));
addpath(genpath('GNSS_signals')); addpath(genpath('frontend'));

%% ---------------- USER CONFIG ----------------
OutRoot   = fullfile(pwd,'datasets_jammertest');
Seed      = 42;

% ----- JAMMERTEST tile length (matches real spectrogram tiles) -----
Fs = 60e6;        % Hz  (fixed to Jammertest)
Ns = 2048;        % samples

% Use at least six satellites; generator should honor this
ParamGNSS = struct('SV_Number', 8);

% Available GNSS bands to randomize per sample
Bands     = {'L1CA','L2C','L5','E1OS'};

% Classes (including NoJam)
Classes   = {'NoJam','Chirp','NB','WB'};

% Splits
Splits    = {'TRAIN','VAL','TEST'};

% --- Choose ONE of these "Counts" styles ---
% (A) Uniform counts per class
Counts.TRAIN = 2000;
Counts.VAL   = 1500;
Counts.TEST  = 1500;

% Stratified C/N0 (dB-Hz) and JSR (dB) bins (uniform within bins)
% Default bins (used when a class does not have a specific override)

CNo_bins_default = [30 35 40 45 50 60 70];
JSR_bins_default = [10 15 20 25 30 35 40 45 50 60 70 80];


CNo_bins_by_class = struct( ...
    'NoJam', [30 40 45 50 55 60 65 70], ...  % NoJam with slightly higher C/N0
    'Chirp', [], ...                         % use CNo_bins_default
    'NB',    [], ...                         % use CNo_bins_default
    'WB',    [] );                           % use CNo_bins_default

JSR_bins_by_class = struct( ...
    'NoJam', [], ...  % jsr = NaN => truly no jammer
    'Chirp', [30 35 40 45 50 60 70 80], ...
    'NB',    [30 35 40 45 50 60 70 80], ...
    'WB',    [40 50 60 70 80] );


% (Optional) Chirp “families” ranges (kept from your version)
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

            % --- Draw C/N0 and JSR for this class ---
            cno_bins_cls = get_bins_for_class(cls, CNo_bins_by_class, CNo_bins_default);
            jsr_bins_cls = get_bins_for_class(cls, JSR_bins_by_class, JSR_bins_default);

            cno = draw_in_bins(cno_bins_cls);
            if strcmpi(cls,'NoJam')
                % For NoJam, by default keep jsr = NaN so the channel truly has no jammer.
                if isempty(jsr_bins_cls)
                    jsr = NaN;
                else
                    jsr = draw_in_bins(jsr_bins_cls);
                end
            else
                jsr = draw_in_bins(jsr_bins_cls);
            end

            % Build jammer parameters for this sample (families kept)
            Pjam = build_jammer_params(cls, band, ParamJamDef, ChirpFamilies);

            % ---- Synthesize (channel handles GNSS, jammer, noise & FE) ----
            [y, meta] = Fct_Channel_Gen([], ParamGNSS, Pjam, Fs, Ns, band, cno, jsr);

            % ---- Meta ----
            if isfield(meta,'CNo_dBHz'); meta.CNR_dBHz = meta.CNo_dBHz; end
            meta.band     = band;
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


function edges = get_bins_for_class(cls, bins_by_class, bins_default)
    % Helper: return the bin edges to use for a given jammer class.
    % - If bins_by_class has a non-empty field "cls", use that.
    % - Otherwise fall back to bins_default.
    if isstruct(bins_by_class) && isfield(bins_by_class, cls) && ~isempty(bins_by_class.(cls))
        edges = bins_by_class.(cls);
    else
        edges = bins_default;
    end
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
            % type set to NoJam; realism comes from RX front-end in Channel
            P = struct('type','NoJam');
        %
        case 'Chirp'
            % Map each Jammertest device family to realistic BW / period:
            %   - 'USB'   → U1.x USB dongle (70–80 MHz, 5–8 µs, L1/E1 flank)
            %   - 'CigS1' → S1.x cigarette lighter, L1 only (30 MHz, 20–40 µs)
            %   - 'CigS2' → S2.x dual-band cigarette lighter (L1+L2),
            %               70–90 MHz, 40–60 µs (long sweeps, problematic for 33 µs tiles)
            %   - 'NEAT'  → H1.1-like handheld (18–24 MHz, 10 µs, L1 or L2)
            %   - 'H3_3'  → 3-band handheld H3.3 (L1/L2/L5, 20/14/17 MHz, 13 µs)
            %   - 'H4_1'  → 4-band handheld H4.1 (L1 wide 100 MHz + E6/L2/L5)
            %
            % The chirp *shape* and edge window come from Def.chirp.*.

            fam  = choose({'USB','CigS1','CigS2','NEAT','H3_3','H4_1'});
            base = struct( ...
                'type',          'Chirp', ...
                'shape',         choose({'sawup','sawdown','tri'}), ...
                'edge_win',      Def.chirp.edge_win, ...
                'osc_offset_Hz', 0 ...
            );

            switch fam
                % ----------------------------------------------------------
                % USB dongle U1.x  (70–80 MHz BW, 5–8 µs period)
                % ----------------------------------------------------------
                case 'USB'
                    base.bw_Hz    = pick([70, 80]) * 1e6;     % 70–80 MHz
                    base.period_s = pick([5, 8])   * 1e-6;    % 5–8 µs
                    base.rf_Hz    = pick([1580, 1595]) * 1e6; % L1/E1 flank
                    P = base;

                % ----------------------------------------------------------
                % Cigarette lighter S1.x (L1 only, 30 MHz, 20–40 µs)
                % ----------------------------------------------------------
                case 'CigS1'
                    base.bw_Hz    = 30e6;                     % 30 MHz
                    base.period_s = pick([20, 40]) * 1e-6;    % 20–40 µs
                    base.rf_Hz    = RF.L1;
                    P = base;

                % ----------------------------------------------------------
                % Cigarette lighter S2.x (L1+L2, *long* sweeps)
                %  - This is the one that causes “partial” chirps in 33 µs
                %    spectrogram tiles: Tper ≈ 40–60 µs.
                %  - We also match the wide BW: 70–90 MHz.
                % ----------------------------------------------------------
                case 'CigS2'
                    cL1 = base;
                    cL1.bw_Hz    = pick([70, 90]) * 1e6;      % 70–90 MHz
                    cL1.period_s = pick([40, 60]) * 1e-6;     % 40–60 µs
                    cL1.rf_Hz    = RF.L1;

                    cL2 = cL1;
                    cL2.rf_Hz    = RF.L2;                     % same sweep on L2

                    P = struct( ...
                        'type',       'Composite', ...
                        'components', {{cL1, cL2}}, ...
                        'weights',    [1, 1] ...
                    );

                % ----------------------------------------------------------
                % NEAT / H1.1-like handheld (around 20 MHz, 10 µs)
                % ----------------------------------------------------------
                case 'NEAT'
                    base.bw_Hz    = pick([18, 24]) * 1e6;     % ≈ 20 MHz
                    base.period_s = 10e-6;                    % 10 µs
                    base.rf_Hz    = choose({RF.L1, RF.L2});   % L1 or L2
                    P = base;

                % ----------------------------------------------------------
                % H3.3: 3-band handheld (L1, L2, L5; fixed 13 µs period)
                % BW: L1 20 MHz, L2 14 MHz, L5 17 MHz
                % ----------------------------------------------------------
                case 'H3_3'
                    c1 = base; c1.period_s = 13e-6; c1.bw_Hz = 20e6; c1.rf_Hz = RF.L1;
                    c2 = base; c2.period_s = 13e-6; c2.bw_Hz = 14e6; c2.rf_Hz = RF.L2;
                    c3 = base; c3.period_s = 13e-6; c3.bw_Hz = 17e6; c3.rf_Hz = RF.L5;

                    % Optional low-level swept spurs to mimic the datasheet
                    sp = struct( ...
                        'enable', true, ...
                        'count',  randi([2, 6]), ...
                        'rel_dB', -20 - 20*rand(), ...         %  -20 .. -40 dBc
                        'bw_Hz',  [0.5e6, 5e6] ...              % narrow swept spurs
                    );

                    P  = struct( ...
                        'type',       'Composite', ...
                        'components', {{c1, c2, c3}}, ...
                        'weights',    [1, 1, 1], ...
                        'spurs',      sp ...
                    );

                % ----------------------------------------------------------
                % H4.1: 4-band handheld
                %  - L1: wide 100 MHz sweep around 1550 MHz
                %  - “E6”: ≈45 MHz around 1260 MHz
                %  - L2: 45 MHz around ≈1220 MHz
                %  - L5: 38 MHz around ≈1182 MHz
                %  - Period: 9 µs on all bands
                % ----------------------------------------------------------
                case 'H4_1'
                    c1 = base; c1.period_s = 9e-6; c1.bw_Hz = 100e6; c1.rf_Hz = 1550e6;
                    cE = base; cE.period_s = 9e-6; cE.bw_Hz = 45e6;  cE.rf_Hz = 1260e6;
                    c2 = base; c2.period_s = 9e-6; c2.bw_Hz = 45e6;  c2.rf_Hz = 1220e6;
                    c5 = base; c5.period_s = 9e-6; c5.bw_Hz = 38e6;  c5.rf_Hz = 1182e6;

                    P = struct( ...
                        'type',       'Composite', ...
                        'components', {{c1, cE, c2, c5}}, ...
                        'weights',    [1, 1, 1, 1] ...
                    );
            end

            %end
        %reference
        % --- NB: PRN at 9 Mcps with short AM flashes on the line ---
        case 'NB'
            P = struct( ...
                'type','PRN', ...
                'rate_Hz', 9e6, ...
                'rolloff', 0.0, ...
                'filter','rect', ...
                'periodicity_s', 1e-3, ...
                'downsample_like_NB', true, ...
                'osc_offset_Hz', (rand<0.5)*-1 + (rand>=0.5)*1 .* (8.9e6 + 0.4e6*rand()), ...
                'rf_Hz', RF.L1 ...
            );
        
            % Spikes like the real spectrograms: very short, thin, as bright as the line
            % --- Mini carrier ticks ON the line (no multiplicative lift) ---
            % 60 MHz, 34 µs tile, STFT nperseg=64 ⇒ time res ~1.07 µs, so keep ticks
            % much shorter than that to look like thin dotted spikes.
            P.nb_cols = struct( ...
               'enable',         true,      ...
               'count',          [8 14],    ...   % spikes per tile (uniform in this range)
               'width_us_min',   0.06,      ...   % 0.06–0.10 µs  (≈ 3–6 samples @ 60 MHz)
               'width_us_max',   0.10,      ...
               'amp_vs_line',    1.15,      ...   % spike amplitude vs. line (≈ same brightness)
               'amp_jitter',     0.12,      ...   % small variation sample to sample
               'tukey_alpha',    0.02,      ...   % near-rect window with sharp center
               'phase_step_rad', 0.6        ...   % tiny PM “tick” → crisp tip, no vertical smear
            );

        
            % Keep NB path clean (no device artifacts)
            P.frontend = struct('enable', true, ...
                'dc_offset', 0, 'iq_gain_imbalance_dB', 0, 'iq_phase_deg', 0, ...
                'amp_flicker_dB', 0.05 + 0.05*rand(), ...
                'spurs', struct('enable', false));



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


        otherwise
            error('Unknown class "%s"', cls);
    end

    % Small emitter-side non-idealities for realism on ALL jammers (not NoJam).
    if ~strcmpi(cls,'NoJam')
        P.frontend = struct( ...
            'enable', true, ...
            'dc_offset', (2e-4)*(randn+1j*randn), ...
            'iq_gain_imbalance_dB', 0.15*(2*rand-1), ...
            'iq_phase_deg', 0.8*(2*rand-1), ...
            'amp_flicker_dB', 0.3*rand(), ...
            'spurs', struct('enable', true, 'count', randi([1,2]), 'rel_dB', -28-5*rand(), 'bw_Hz', [0.2e6, 1.5e6]) ...
        );
    end
        % Strengthen slow AM flicker for NB to mimic the mild vertical "ticks"
    if strcmp(cls,'NB')
        % Keep NB visually clean, like your field captures
        P.frontend.dc_offset = 0;             % kill DC line at 0 MHz
        P.frontend.iq_gain_imbalance_dB = 0;  % no IQ skew
        P.frontend.iq_phase_deg = 0;          % no phase error
        if isfield(P.frontend,'spurs'); P.frontend.spurs.enable = false; end
        P.frontend.amp_flicker_dB = 0.05 + 0.05*rand();  % very light (0.05–0.10 dB p-p)
    end




    if ~strcmp(cls,'NoJam') && ~isfield(P,'osc_offset_Hz')
        P.osc_offset_Hz = pick([-0.5, 0.5])*1e6;
    end
end
