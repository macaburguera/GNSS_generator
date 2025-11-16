function [x, meta] = jam_fh(N, Fs, p)
% Frequency-hopping jammer: hop set + hop jitter + local NB step BW
t = (0:N-1).'/Fs;

hoprate = getf(p,'hoprate', 1200);
hopjit  = getf(p,'hopjit', 0.5);
fcset   = getf(p,'fcset',  ((-3:3)/3)*0.35*Fs);
stepBW  = getf(p,'stepBW', 200e3);
am_pm   = getf(p,'am_pm',[0.2 0.2]);

% Build per-hop segments
Thop = 1/max(hoprate,1);  % seconds per hop
Ns_hop = max(16, round(Thop*Fs));
idx = 1;
x = complex(zeros(N,1));
while idx <= N
    fc = fcset(1 + mod(randi(1e6), numel(fcset)));
    % NB step (Gaussian NB around fc)
    L = max(63, 2*round(Fs/stepBW)+1);
    b = fir1(L-1, min(0.99, stepBW/(Fs/2)));
    u = randn(min(Ns_hop, N-idx+1),1);
    s = filter(b,1,u);
    tt = (0:numel(s)-1).'/Fs;
    % AM/PM
    am = 1 + am_pm(1)*sin(2*pi*(200+rand()*4e3)*tt + 2*pi*rand());
    pm = am_pm(2)*sin(2*pi*(200+rand()*4e3)*tt + 2*pi*rand());
    seg = am .* s .* exp(1j*(2*pi*fc*tt + pm + 2*pi*rand()));
    x(idx:idx+numel(seg)-1) = seg;

    % next hop with jitter
    hop_scale = max(0.3, min(1.7, 1 + hopjit*(randn()*0.25)));
    Ns_hop = max(16, round(Ns_hop*hop_scale));
    idx = idx + numel(seg);
end

x = apply_burst(x, p);
meta = struct('hoprate',hoprate,'hopjit',hopjit,'fcset',fcset,'stepBW',stepBW,'am_pm',am_pm);
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
