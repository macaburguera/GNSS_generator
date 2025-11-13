function y = jam_wb_prn(fs, N, chip_rate_Hz, rolloff, osc_offset_Hz)
% ~10 MHz BPSK PRN (H1.1 WB). Same as NB but faster chips.

Lchips = ceil(N * chip_rate_Hz / fs) + 8;
chips  = prn_mseq(Lchips);
sps    = max(2, round(fs / chip_rate_Hz));
ups    = upsample(chips, sps);
span   = 8;
h      = rrc_filter_local(rolloff, span, sps);
bb     = conv(ups, h, 'same'); bb = bb(1:N);
t      = (0:N-1).' / fs;
if ~isempty(osc_offset_Hz) && osc_offset_Hz ~= 0
    bb = bb .* exp(1j*2*pi*osc_offset_Hz*t);
end
y = bb / (rms(bb)+eps);
end
