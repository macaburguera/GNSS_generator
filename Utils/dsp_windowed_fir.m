
function h = dsp_windowed_fir(Fs, Fpass, Ntaps, type)
%DSP_WINDOWED_FIR Simple Hamming-windowed FIR design.
%   type: 'low', 'high', 'bandpass'
    if nargin < 4, type = 'low'; end
    if nargin < 3 || isempty(Ntaps), Ntaps = 257; end
    if mod(Ntaps,2)==0, Ntaps = Ntaps+1; end
    switch lower(type)
        case 'low'
            Wn = min(0.999, Fpass/(Fs/2));
            h = fir1(Ntaps-1, Wn, 'low', hamming(Ntaps));
        case 'high'
            Wn = min(0.999, Fpass/(Fs/2));
            h = fir1(Ntaps-1, Wn, 'high', hamming(Ntaps));
        case 'bandpass'
            if numel(Fpass)~=2, error('Bandpass requires [F1 F2]'); end
            Wn = min(0.999, Fpass/(Fs/2));
            h = fir1(Ntaps-1, Wn, 'bandpass', hamming(Ntaps));
        otherwise
            error('Unknown type');
    end
    h = h(:);
end
