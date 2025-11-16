
function x = fe_apply_bpf_ripple(x, Fs, cfg)
%FE_APPLY_BPF_RIPPLE Apply front-end bandpass ripple and group delay.
% cfg fields:
%   .BpHz      : passband half-width (Hz), e.g., 8e6 around DC
%   .RippleDb  : ripple depth (dB p-p) across band (e.g., 1 dB)
%   .Ntaps     : FIR length
%   .TiltDb    : linear tilt (dB from -Bp to +Bp)
    if ~isfield(cfg,'BpHz') || cfg.BpHz<=0
        x = x; return;
    end
    B = cfg.BpHz;
    Ntaps = 257;
    if isfield(cfg,'Ntaps'), Ntaps = cfg.Ntaps; end
    % Start with a flat LP to B
    h = dsp_windowed_fir(Fs, B, Ntaps, 'low');
    % Apply simple ripple via frequency-domain windowing
    H = fft(h, 8192).';
    f = linspace(-Fs/2, Fs/2, numel(H)).';
    H = fftshift(H);
    % ripple as cosine across band
    rip = 0;
    if isfield(cfg,'RippleDb') && cfg.RippleDb>0
        A = cfg.RippleDb/2;
        rip = db2lin(A*cos(pi*f/B));
    else
        rip = ones(size(f));
    end
    if isfield(cfg,'TiltDb') && cfg.TiltDb~=0
        tilt = db2lin((cfg.TiltDb)*(f/(B)));
        rip = rip .* tilt;
    end
    H = H .* rip;
    H = ifftshift(H);
    h = real(ifft(H));
    h = h(1:Ntaps); % back to Ntaps
    x = filter(h, 1, x);
end
