function [y, meta] = Fct_Channel_Gen(~, ParamGNSS, ParamJam, fs, N, band, CNo_dBHz, JSR_dB)
% Builds GNSS + Jammer + AWGN with target C/N0 and JSR.
% RF-aware (rf_Hz -> baseband offset) and Composite-aware.

    if nargin < 8 || isempty(JSR_dB),   JSR_dB   = NaN; end
    if nargin < 7 || isempty(CNo_dBHz), CNo_dBHz = 45;  end

    % ---- SV count ----
    SVs = 6;
    if isstruct(ParamGNSS) && isfield(ParamGNSS,'SV_Number')
        SVs = max(6, ParamGNSS.SV_Number);
    end

    band_tok = map_band_token(band);

    % ---------- GNSS composite ----------
    T  = N / fs;                      % target time [s]
    T0 = base_period_s(band_tok);     % fundamental code period (approx)
    n_periods = max(1, ceil(T / T0)); % always ≥1 whole code period


    try
        [I, Q] = GNSSsignalgen(SVs, band_tok, fs, n_periods);
        x_gnss = complex(I(:), Q(:));
    catch
        % Fallback: noise-like GNSS if generator not available
        x_gnss = gnss_like_noise(SVs, fs, N);
    end

    % Enforce exactly N samples
    if numel(x_gnss) < N
        x_gnss = repmat(x_gnss, ceil(N/numel(x_gnss)), 1);
    end
    x_gnss = x_gnss(1:N);

    % Normalize GNSS power to 1
    Ps = mean(abs(x_gnss).^2); if Ps <= 0, Ps = 1; end
    x_gnss = x_gnss / sqrt(Ps);

    % ---------- Jammer (RF- & Composite-aware) ----------
    if isfield(ParamJam,'type') && ~strcmpi(ParamJam.type,'NoJam')
        [x_jam, jam_meta] = build_jam_wave(ParamJam, fs, N, band_tok);
        Pj = mean(abs(x_jam).^2); if Pj <= 0, Pj = 1; end
        if ~isnan(JSR_dB)
            x_jam = x_jam * sqrt(10^(JSR_dB/10) / Pj);    % JSR wrt Ps=1
        end
    else
        x_jam = zeros(N,1);
        jam_meta = struct();
    end

    % ---------- AWGN for target C/N0 ----------
    % For complex baseband: sigma^2 = N0*fs ; C/N0 = Ps/N0  (Ps=1)
    CNo_lin = 10^(CNo_dBHz/10);
    N0      = 1 / CNo_lin;
    sigma2  = N0 * fs;
    n = sqrt(sigma2/2) * (randn(N,1) + 1j*randn(N,1));

    % ---------- Output ----------
    y = x_gnss + x_jam + n;

    if isfield(ParamJam,'type') && ~strcmpi(ParamJam.type,'NoJam')
        JSR_val = JSR_dB;
    else
        JSR_val = NaN;
    end
    meta = struct('CNo_dBHz', CNo_dBHz, ...
                  'JSR_dB',   JSR_val, ...
                  'band',     band_tok, ...
                  'jam_meta', jam_meta);
end

% ===================== Local helpers =====================
function [x, jmeta] = build_jam_wave(P, fs, N, band_tok)
    % Composite: sum components
    if isfield(P,'type') && strcmpi(P.type,'Composite')
        if ~isfield(P,'components') || isempty(P.components)
            x = zeros(N,1);
            jmeta = struct('kind','Composite','note','empty-composite','components',{{}});
            return;
        end

        x = zeros(N,1);

        % --- NORMALIZE WEIGHTS HERE ---
        if isfield(P,'weights') && ~isempty(P.weights)
            w = P.weights(:);
            if any(w)                      % avoid division by zero
                P.weights = (w / norm(w)).';  % row vector with unit L2 norm
            end
        end
        % -------------------------------

        jmeta = struct();
        jmeta.kind = 'Composite';
        jmeta.components = cell(1,numel(P.components));

        for k = 1:numel(P.components)
            Pk = apply_dc_from_rf(P.components{k}, fs, band_tok);
            [xk, mk] = call_factory(Pk, fs, N);

            % weight for this branch (defaults to 1 if missing)
            if isfield(P,'weights') && ~isempty(P.weights) && k <= numel(P.weights)
                wk = P.weights(k);
            else
                wk = 1;
            end

            x = x + wk * xk;
            jmeta.components{k} = mk;
        end

        % optional spurs
        if isfield(P,'spurs') && isfield(P.spurs,'enable') && P.spurs.enable
            x = x + synth_spurs(P.spurs, fs, N);
        end
        return;
    end

    % Single jammer ...


    % Single jammer
    Pn = apply_dc_from_rf(P, fs, band_tok);
    [x, jmeta] = call_factory(Pn, fs, N);
end


function [x, mk] = call_factory(P, fs, N)
    x = jammer_factory(P, fs, N);
    x = x(:);
    mk = P;
end

function P2 = apply_dc_from_rf(P, fs, band_tok)
    P2 = P;
    if isfield(P,'rf_Hz')
        f0 = rf_center_hz(band_tok);
        dc = P.rf_Hz - f0;
        dc = mod(dc + fs/2, fs) - fs/2; % fold inside Nyquist
        switch lower(P.type)
            case {'prn','nb','wb','chirp','fh'}
                if ~isfield(P2,'osc_offset_Hz'), P2.osc_offset_Hz = 0; end
                P2.osc_offset_Hz = P2.osc_offset_Hz + dc;
            case 'cw'
                if ~isfield(P2,'tone_offset_Hz'), P2.tone_offset_Hz = 0; end
                P2.tone_offset_Hz = P2.tone_offset_Hz + dc;
            case 'cwcomb'
                if ~isfield(P2,'offsets_Hz'), P2.offsets_Hz = 0; end
                P2.offsets_Hz = P2.offsets_Hz + dc;
        end
    end
end

function f0 = rf_center_hz(token)
    switch upper(token)
        case {'L1','L1CA','E1','E1OS','E1OS_B','E1OS_C','E1OS+','E1OS+_C'}
            f0 = 1575.42e6;
        case {'L2','L2C','L2CM','L2CL'}
            f0 = 1227.60e6;
        case {'L5','E5A','E5B','E5','E5+'}
            f0 = 1191.795e6;
        case {'G1','G1C'}
            f0 = 1602.0e6;
        otherwise
            f0 = 1575.42e6;
    end
end

function token = map_band_token(band)
    if ischar(band) || isstring(band)
        token = upper(char(band));
    else
        token = 'L1';
    end
end

function T0 = base_period_s(token)
    switch upper(token)
        case {'L1','L1CA','E1','E1OS'}
            T0 = 1e-3;  % 1 ms
        case {'L2','L2C','L2CM','L2CL'}
            T0 = 1e-3;
        case {'L5','E5A','E5B','E5'}
            T0 = 1e-3;
        otherwise
            T0 = 1e-3;
    end
end

function x = gnss_like_noise(SVs, fs, N)
    x = zeros(N,1);
    for k=1:SVs
        foff = (rand()-0.5)*0.2*fs; % a bit of structure
        x = x + exp(1j*2*pi*foff*(0:N-1).'/fs) .* (randn(N,1)+1j*randn(N,1));
    end
    x = x ./ sqrt(mean(abs(x).^2));
end

function x = synth_spurs(S, fs, N)
    x = zeros(N,1);
    if ~isfield(S,'count'),  return; end
    nsp = max(0, S.count);
    for i=1:nsp
        bw = (S.bw_Hz(1) + (S.bw_Hz(2)-S.bw_Hz(1))*rand());
        fc = (rand()-0.5)*0.8*fs;
        t  = (0:N-1).'/fs;
        s  = randn(N,1) + 1j*randn(N,1);
        L  = max(8, round(fs/bw));
        b  = hamming(L); b = b/sum(b);
        s  = conv(s, b, 'same');
        s  = s .* exp(1j*2*pi*fc*t);
        rel = 10^((S.rel_dB)/20);
        x = x + rel*s;
    end
end
