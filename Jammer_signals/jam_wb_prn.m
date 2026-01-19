function [x, meta] = jam_wb_prn(N, Fs, p)
% STRONG wideband noise jammer

fc      = getf(p,'fc', 0.0);  % keep it centred for now
bw_frac = getf(p,'bw_frac', 0.6 + 0.3*rand());  % 60–90% of Fs
bw      = bw_frac * Fs;

% 1) white complex noise
w = (randn(N,1) + 1j*randn(N,1)) / sqrt(2);

% 2) design wide low-pass to approximate |H(f)| ≈ 1 in [-bw/2, bw/2]
M  = max(511, 2*round(Fs/bw)*64 + 1);     % long enough for reasonably sharp edges
b  = fir1(M-1, (bw/2)/(Fs/2));            % normalized cutoff

x = filter(b, 1, w);

% 3) (optional) very gentle ripple ≤ 1 dB so it still looks flat-ish
%    If you keep your FFT-based comb, clamp ripple strongly:
%    ripple_db = getf(p,'ripple', 0.5);  % pk-pk <= 0.5 dB

% 4) normalize to unit power (Channel_Gen will scale by JSR_dB)
x = x ./ sqrt(mean(abs(x).^2) + 1e-12);

% 5) apply bursts if you want temporal structure
x = apply_burst(x, p);

meta = struct('fc', fc, 'bw', bw, 'bw_frac', bw_frac);
end


function x = apply_burst(x, p)
b = getf(p,'burst', struct('duty',1,'len',numel(x)));
N = numel(x); on = round(b.duty * N);
if on>=N || b.duty>=0.999, return; end
gate = [ones(on,1); zeros(N-on,1)];
gate = circshift(gate, randi([0 N-1]));
x = x .* gate;
end
function v = getf(s,f,d), if nargin<3,d=[];end; if isempty(s)||~isstruct(s)||~isfield(s,f), v=d; else, v=s.(f); end; end
