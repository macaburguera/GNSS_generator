function y = jam_nb_prn(fs, N, chip_rate_Hz, rolloff, osc_offset_Hz)
% ~1 MHz BPSK PRN (H1.1 NB). Shaped with RRC.

Lchips = ceil(N * chip_rate_Hz / fs) + 4; % a few extra
chips  = prn_mseq(Lchips);                % ±1
% Upsample to samples:
sps = max(2, round(fs / chip_rate_Hz));
ups = upsample(chips, sps);
% RRC pulse shape:
span = 8; % symbols
h = rrc_filter_local(rolloff, span, sps);
bb = conv(ups, h, 'same');
bb = bb(1:N);

t = (0:N-1).' / fs;
if ~isempty(osc_offset_Hz) && osc_offset_Hz ~= 0
    bb = bb .* exp(1j*2*pi*osc_offset_Hz*t);
end
y = bb / (rms(bb)+eps);
end
