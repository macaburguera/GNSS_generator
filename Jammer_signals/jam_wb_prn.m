function [x, meta] = jam_wb_prn(N, Fs, p)
% Wideband noise/PRN jammer with gentle ripple and bursts
fc     = getf(p,'fc', 0.0);
bw     = getf(p,'bw', 12e6);
ripple = getf(p,'ripple', 1.0); % dB pk-pk

% Start with WGN -> band-limit with FIR
w = randn(N,1) + 1j*randn(N,1);
M = max(255, 2*round(Fs/bw)+1);
b = fir1(M-1, min(0.99, (bw/2)/(Fs/2)));
s = filter(b,1,w);

% Impose gentle passband ripple by comb-like EQ
H = fft(s);
L = numel(H);
k = (0:L-1).';
rip = (ripple/20*log(10)) * sin(2*pi*(rand()*0.02 + 0.005)*k + 2*pi*rand()); %#ok<NASGU>
% (Keep it simple—small random tilt)
tilt = (10^(ripple/40)) .^ linspace(-0.5,0.5,L).';
H = H .* (1 + 0.07*(randn(L,1))) .* tilt;
s = ifft(H, 'symmetric');

t = (0:N-1).'/Fs;
x = s .* exp(1j*(2*pi*fc*t + 2*pi*rand()));
x = apply_burst(x, p);

meta = struct('fc',fc,'bw',bw,'ripple',ripple);
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
