function y = jam_fh(fs, N, start_offset_Hz, step_Hz, num_tones, dwell_s, phase_cont)
% 6-tone FH like H1.3: hop +200 kHz every 50 ms across ~1 MHz (loop).
t = (0:N-1).' / fs;

freqs = start_offset_Hz + step_Hz*(0:num_tones-1);
dwellN = max(1, round(dwell_s * fs));
idx = floor((0:N-1)/dwellN);
idx = mod(idx, num_tones) + 1;

ph = zeros(N,1);
y  = zeros(N,1);
phi_c = 0;
for k = 1:N
    f = freqs(idx(k));
    if k==1 || ~phase_cont && mod(k-1,dwellN)==0
        phi_c = 0; % reset phase on hop if not continuous
    end
    if k>1
        phi_c = phi_c + 2*pi*f/fs;
    end
    y(k) = exp(1j*phi_c);
end
end
