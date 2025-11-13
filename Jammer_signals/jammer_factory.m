function x = jammer_factory(P, fs, N)
%JAMMER_FACTORY  Generate jammer waveform (complex baseband).
% Supports: NoJam, CW, CWcomb, Chirp, PRN, NB, WB, FH, Composite

t  = (0:N-1).'/fs;
typ = lower(fget(P,'type','nojam'));

switch typ

    case 'nojam'
        x = complex(zeros(N,1));

    % -------- CW single tone with optional drift/flicker --------
    case 'cw'
        f0   = fget(P,'tone_offset_Hz',0);
        fdot = fget(P,'freq_drift_Hzps',0);        % Hz/s
        Aflk = fget(P,'amp_flicker_dB',0);         % dB p-p slow AM
        f_t  = f0 + fdot*(t - t(1));
        phi  = 2*pi*cumsum(f_t)/fs;
        x    = exp(1j*phi);
        if Aflk>0
            m   = 10^(Aflk/20);
            env = 1 + (m-1)*sin(2*pi*200*t);       % very slow AM
            x   = x .* env;
        end

    % -------- CW multi-tone comb --------
    case 'cwcomb'
        offs = fget(P,'offsets_Hz',[-5e6 0 5e6]);
        x = zeros(N,1);
        for k=1:numel(offs), x = x + exp(1j*2*pi*offs(k)*t); end

    % -------- PRN/BPSK (generic NB/WB) --------
    % ---------------- PRN/BPSK (generic NB/WB) ----------------
    case {'prn','nb','wb'}
        % accept both “rate_Hz” and legacy “chip_rate_Hz”
        Rchip = fget(P,'rate_Hz',fget(P,'chip_rate_Hz',2e6));
        ro    = fget(P,'rolloff',0.2);
        filt  = lower(fget(P,'filter','rrc'));    % 'rrc' or 'rect'
        fOff  = fget(P,'osc_offset_Hz',0);
    
        spc   = max(2, round(fs/Rchip));         % samples per chip
    
        % Optional periodicity (e.g., 9 Mcps with 1 ms repetition)
        perT        = fget(P,'periodicity_s',0);
        hasPeriod   = (perT > 0);
        chipsPer    = 0;
        if hasPeriod
            chipsPer = max(1, round(perT * Rchip));  % e.g., 9000 for 9e6 * 1e-3
        end
    
        % Length needed to safely cover the tile after upsampling
        % (N/spc chips plus a cushion). Also ensure >= chipsPer when periodic.
        Lchips_need = ceil(N / spc) + 100;
        Lchips_eff  = max(Lchips_need, chipsPer);
    
        % Generate base PN chips
        chips = 2*randi([0,1], Lchips_eff, 1) - 1;   % ±1
    
        % Force periodic repetition if requested
        if hasPeriod
            % Repeat the first 'chipsPer' chips to fill Lchips_eff
            reps  = ceil(Lchips_eff / chipsPer);
            chips = repmat(chips(1:chipsPer), reps, 1);
            chips = chips(1:Lchips_eff);             % trim exact
        end
    
        % Upsample to waveform
        s  = upsample(chips, spc);
    
        % Shape it
        switch filt
            case 'rrc'
                try
                    h = firrcos(128, Rchip/2, ro, fs, 'rolloff', 'sqrt');
                catch
                    fc = min(0.49, ((Rchip*(1+ro)/2)/(fs/2)));
                    h  = fir1(128, fc);
                end
            otherwise % 'rect'
                fc = min(0.49, (Rchip/2)/(fs/2));
                h  = fir1(64, fc);
        end
        y  = filter(h,1,s);
    
        % Ensure we have enough samples, then crop to N
        if numel(y) < N
            y = repmat(y, ceil(N/numel(y)), 1);
        end
        y = y(1:N);
    
        % emulate “aliased/blurred NB from 9M” by decimating & LP back
        if logical(fget(P,'downsample_like_NB',0))
            q = max(2, round(Rchip/1e6));  % e.g., 9 for 9 Mcps
            try
                y = resample(y, 1, q);
            catch
                y = decimate(y, q);        % fallback if resample is unavailable
            end
            if numel(y) < N, y = repmat(y, ceil(N/numel(y)), 1); end
            y = y(1:N);
            y = filter(fir1(96, 0.15), 1, y);  % blur a bit
        end
    
        x = y .* exp(1j*2*pi*fOff*t);


    % -------- Linear chirp (saw/tri) with duty and reset blip --------
    case 'chirp'
        BW    = fget(P,'bw_Hz',25e6);
        Tper  = fget(P,'period_s',8e-6);
        shape = lower(fget(P,'shape','sawup'));      % 'sawup'|'sawdown'|'tri'
        fOff  = fget(P,'osc_offset_Hz',0);
        duty  = max(0,min(1,fget(P,'duty',1)));
        rblip = fget(P,'reset_blip_dB',0);

        Nper  = max(2, round(Tper*fs));
        idx   = (0:N-1).';
        idxIn = mod(idx, Nper);

        switch shape
            case 'sawdown', frac = 1 - idxIn/Nper;
            case 'tri'
                frac = idxIn/Nper; frac = 2*abs(frac - 0.5);
            otherwise
                frac = idxIn/Nper;
        end

        finst = (-BW/2) + BW*frac + fOff;

        if duty<1
            actN = round(duty*Nper);
            active = idxIn < actN;
            finst(~active) = fOff;
        end
        phase = 2*pi*cumsum(finst)/fs;
        x     = exp(1j*phase);

        if rblip>0
            spikes = (idxIn==0);
            amp    = 10^(rblip/20);
            x(spikes) = amp * x(spikes);
        end

        alpha = fget(P,'edge_win',0);
        if alpha>0, x = x .* my_tukeywin(N, min(max(alpha,0),1)); end

    % -------- Frequency hopping --------
    case 'fh'
        K      = fget(P,'num_tones',6);
        stepHz = fget(P,'step_Hz',2e6);
        dwell  = fget(P,'dwell_s',20e-6);
        contPh = logical(fget(P,'phase_continuous',1));
        fStart = fget(P,'start_offset_Hz',-stepHz*floor(K/2));
        hopJit = fget(P,'hop_jitter_Hz',0.05*stepHz);
        duty   = max(0,min(1,fget(P,'duty',1)));

        freqs  = fStart + stepHz*(0:K-1);
        dwellN = max(1, round(dwell*fs));
        x      = zeros(N,1);  phi = 0;
        n = 1;
        while n<=N
            perm = randperm(K);
            for kk = 1:K
                k  = perm(kk);
                n2 = min(N, n+dwellN-1);
                tt = (n:n2).'/fs;
                fk = freqs(k) + hopJit*(2*rand-1);
                if contPh
                    seg = exp(1j*(phi + 2*pi*fk*(tt - tt(1))));
                    phi = angle(seg(end));
                else
                    seg = exp(1j*2*pi*fk*tt);
                end
                if duty<1
                    act  = round(duty*numel(seg));
                    seg((act+1):end) = 0;
                end
                x(n:n2) = seg;
                n = n2+1; if n>N, break; end
            end
        end

    % -------- Composite (handled in Channel, present for completeness) --------
    case 'composite'
        comps   = fget(P,'components',{}); w = fget(P,'weights',ones(1,numel(comps)));
        w       = w(:).'/max(1e-12, norm(w));
        x = zeros(N,1);
        for i=1:numel(comps)
            xi = jammer_factory(comps{i}, fs, N);
            x  = x + w(i) * (xi * exp(1j*2*pi*rand()));
        end
        S = fget(P,'spurs',struct('enable',false));
        if isstruct(S) && fget(S,'enable',false)
            M   = fget(S,'count',3);
            rel = fget(S,'rel_dB',-25);  g = 10^(rel/20);
            BW  = fget(S,'bw_Hz',[0.5e6, 3e6]);
            for m=1:M
                bwm = BW(1) + (BW(2)-BW(1))*rand();
                per = (6e-6 + 8e-6*rand());
                xi  = jammer_factory(struct('type','chirp','bw_Hz',bwm,'period_s',per), fs, N);
                x   = x + g * xi;
            end
        end

    otherwise
        error('jammer_factory: Unknown jammer type "%s"', typ);
end

% apply small common oscillator offset if provided
fOffGlobal = fget(P,'osc_offset_Hz',[]);
if ~isempty(fOffGlobal), x = x .* exp(1j*2*pi*fOffGlobal*t); end

% Normalize jammer power to 1 (channel will scale to JSR)
Pj = mean(abs(x).^2); if Pj<=0, Pj=1; end
x  = x / sqrt(Pj);
end

% ---------- helpers ----------
function v = fget(S, name, default)
    if isstruct(S) && isfield(S,name) && ~isempty(S.(name))
        v = S.(name);
    else
        v = default;
    end
end

function h = try_firrcos(N, Fc, R, Fs)
    try
        h = firrcos(N, Fc, R, Fs, 'rolloff', 'sqrt');
    catch
        fc = min(0.49, (Fc*(1+R))/(Fs/2));
        h  = lp_fir(N, fc);
    end
end

function h = lp_fir(N, Wn)
% Hamming-windowed sinc LPF. Wn in (0..1) normalized to Nyquist.
    n = (0:N)'; M = N/2;
    m = n-M;
    h = zeros(size(n));
    for i=1:numel(n)
        if m(i)==0
            h(i) = 2*Wn;
        else
            h(i) = sin(2*pi*Wn*m(i)) / (pi*m(i));
        end
    end
    ham = 0.54 - 0.46*cos(2*pi*(0:N)'/N);
    h = h .* ham;
    h = h / sum(h);
end

function w = my_tukeywin(N, alpha)
% Minimal Tukey window (alpha in [0,1])
    if alpha <= 0
        w = ones(N,1); return
    elseif alpha >= 1
        w = hann(N); return
    end
    w = ones(N,1);
    per = alpha*(N-1)/2;
    for n=0:N-1
        if n < per
            w(n+1) = 0.5 * (1 + cos(pi*(2*n/(alpha*(N-1)) - 1)));
        elseif n > (N-1 - per)
            w(n+1) = 0.5 * (1 + cos(pi*(2*n/(alpha*(N-1)) - 2/alpha + 1)));
        else
            w(n+1) = 1;
        end
    end
end

function y = resample_like(x, p, q)
% Crude integer downsample approximation (p ignored, q>=1)
    if q<=1, y = x; return; end
    y = x(1:q:end);
    % zero-order hold back close to original scale (not perfect; good enough for “blur” effect)
    y = repelem(y, q);
end
