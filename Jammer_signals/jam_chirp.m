function [x, meta] = jam_chirp(N, Fs, p)
% Linear (slightly curved) chirp with sweep jitter + AM/PM and bursts
t = (0:N-1).'/Fs;

fc0  = getf(p,'fc0', 0.0);
slope= getf(p,'slope', (Fs*0.4)/(2e-3));   % Hz/s
curv = getf(p,'curv',  0.0);               % Hz/s^2
sj   = getf(p,'sweepjit', 0.6);
ap   = getf(p,'am_pm',[0.25 0.2]);

% sweep law with small jitter (random lowpass noise)
jit = filter(fir1(63, 0.02), 1, randn(N,1)) * sj * (Fs*0.02);
f_t = fc0 + slope*t + 0.5*curv*(t.^2) + jit;

phi = 2*pi*cumtrapz(t, f_t) + 2*pi*rand();
am  = 1 + ap(1)*sin(2*pi*(400+rand()*6e3)*t + 2*pi*rand());
pm  = ap(2)*sin(2*pi*(300+rand()*6e3)*t + 2*pi*rand());

x = am .* exp(1j*(phi + pm));
x = apply_burst(x, p);

meta = struct('fc0',fc0,'slope',slope,'curv',curv,'sweepjit',sj,'am_pm',ap);
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
