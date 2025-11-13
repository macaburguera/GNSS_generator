function y = jam_chirp(fs, N, bw_Hz, period_s, edge_win, osc_offset_Hz)
% Sawtooth LFM baseband jammer: instantaneous frequency sweeps linearly
% from -bw/2 to +bw/2 each period, then resets (sawtooth). Optional offset.
% fs: sample rate; N: samples; bw_Hz: sweep BW; period_s: sweep period.

t = (0:N-1).' / fs;                  % column
% phase increment rate (Hz/s) for linear sweep:
f_start = -bw_Hz/2;
f_end   = +bw_Hz/2;
T = max(period_s, 1/fs);
% Position inside period:
tau = mod(t, T);
% Instantaneous frequency:
finst = f_start + (f_end - f_start) .* (tau / T);

% Optional cosmetic taper near edges to avoid clicks at reset:
if edge_win > 0
    ramp = 0.5 * (1 - cos(pi * min(tau, T - tau) / max(edge_win*T, eps)));
    finst = finst .* (0.5 + 0.5 * ramp);
end

% Integrate frequency to phase:
phi = 2*pi * cumsum(finst) / fs;

% Optional oscillator offset:
if ~isempty(osc_offset_Hz) && osc_offset_Hz ~= 0
    phi = phi + 2*pi*osc_offset_Hz*t;
end

y = exp(1j * phi);
end
