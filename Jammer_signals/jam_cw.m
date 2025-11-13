function y = jam_cw(fs, N, tone_offset_Hz)
t = (0:N-1).' / fs;
y = exp(1j*2*pi*tone_offset_Hz*t);
end
