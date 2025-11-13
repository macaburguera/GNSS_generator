function [yj, scale] = scale_to_jsr(x_gnss, yj_raw, fs, band, targetJSR_dB)
% Scales jammer to achieve target JSR (dB) measured IN-BAND.
[fmin,fmax] = band_lims(band);
N = numel(x_gnss);
% In-band masking via simple FFT window:
X = fftshift(fft(x_gnss));
Y = fftshift(fft(yj_raw));
f = linspace(-fs/2, fs/2, N).';
mask = (f>=fmin) & (f<=fmax);
Pg = mean(abs(X(mask)).^2)+eps;
Pj = mean(abs(Y(mask)).^2)+eps;
JSR_now = 10*log10(Pj/Pg);
delta = targetJSR_dB - JSR_now;
scale = 10^(0.5*delta/10);
yj = yj_raw * scale;
end
