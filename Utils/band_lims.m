function [fmin,fmax] = band_lims(band)
% L-band limits as used in the test plan (Hz relative to RF center).
% (Used to set in-band windows for JSR/CN0 calculations.)
switch upper(band)
    case 'L1' % 1563–1587 MHz
        fmin = -12e6; fmax = +12e6;
    case 'L2' % 1215–1239.6 MHz
        fmin = -12e6; fmax = +12e6;
    case 'L5' % 1164–1189 MHz
        fmin = -12.5e6; fmax = +12.5e6;
    case 'E1' % 1559–1591 MHz
        fmin = -16e6; fmax = +16e6;
    case 'E5A' % 1164–1189
        fmin = -12.5e6; fmax = +12.5e6;
    case 'G1' % 1593–1610
        fmin = -8.5e6; fmax = +8.5e6;
    otherwise
        fmin = -12e6; fmax = +12e6;
end
end
