function [x, meta] = jam_cw(N, Fs, p)
% Realistic CW: frequency wander + AM/PM ripple + bursty duty cycle
t = (0:N-1).'/Fs;
fc = getf(p,'fc', 0.0);

% AM/PM ripple
am_depth = getf(p,'am_pm',[0.15 0.15]); am_depth = am_depth(1);
pm_depth = getf(p,'am_pm',[0.15 0.15]); pm_depth = pm_depth(2);
am_f = getf(p,'am_f', 1000);
pm_f = getf(p,'pm_f',  1200);

am = 1 + am_depth * sin(2*pi*am_f*t + 2*pi*rand());
phi = pm_depth * sin(2*pi*pm_f*t + 2*pi*rand());

% Slow frequency wander (integrated noise)
wd = getf(p,'wander',struct('sigma',5,'fcorner',20));
phi_wander = cumsum((wd.sigma*2*pi/Fs) * lowpass_white(N, wd.fcorner, Fs));

x = am .* exp(1j*(2*pi*fc*t + phi + phi_wander + 2*pi*rand()));
x = apply_burst(x, p);

meta = struct('fc',fc,'am_depth',am_depth,'pm_depth',pm_depth,'am_f',am_f,'pm_f',pm_f);
end

function y = lowpass_white(N, fc, Fs)
w = randn(N,1);
if fc<=0, y = w; return; end
M = max(31, 2*round(Fs/fc)+1);
b = fir1(M-1, min(0.99, fc/(Fs/2)));
y = filter(b,1,w);
end

function x = apply_burst(x, p)
b = getf(p,'burst', struct('duty',1,'len',numel(x)));
if ~isfield(b,'duty'), b.duty=1; end
if ~isfield(b,'len'),  b.len=numel(x); end
N = numel(x); on = round(b.duty*b.len);
if on>=N || b.duty>=0.999, return; end
gate = [ones(on,1); zeros(N-on,1)];
gate = circshift(gate, randi([0 N-1]));
x = x .* gate;
end

function v = getf(s, f, d)
if nargin<3, d=[]; end
if isempty(s)||~isstruct(s)||~isfield(s,f), v=d; else, v=s.(f); end
end
