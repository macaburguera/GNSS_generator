function [x, meta] = jam_nb_prn(N, Fs, p)
% Narrowband PRN/noise-like jammer (RRC-ish shaped), with AM/PM ripple + bursts
t = (0:N-1).'/Fs;

fc   = getf(p,'fc', 0.0);
bw   = getf(p,'bw', 200e3);
roll = getf(p,'roll', 0.35);
am_pm= getf(p,'am_pm',[0.2 0.15]);

% Base BPSK with low chip-rate ~ BW
Rchip = max(10e3, 0.5*bw);
chips = 2*(randi([0 1], ceil(N*Rchip/Fs)+10,1))-1;
% Upsample by ZOH then filter with SRRC-ish FIR
idx = floor((0:N-1).' * Rchip / Fs) + 1; base = chips(idx);
L = max(63, 2*round(Fs/(bw))+1);
b = fir1(L-1, min(0.99,bw/(Fs/2)));
s = filter(b,1, base);

% Apply AM/PM small ripples, slow drift
am = 1 + am_pm(1)*sin(2*pi*(200+rand()*5e3)*t + 2*pi*rand());
pm = am_pm(2)*sin(2*pi*(300+rand()*5e3)*t + 2*pi*rand());
drift = 2*pi*fc*t + 2*pi*rand();

x = am .* s .* exp(1j*(drift + pm));
x = apply_burst(x, p);

% Re-center band (if fc large, it's already inside exp term)
meta = struct('fc',fc,'bw',bw,'roll',roll,'am_pm',am_pm);
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
