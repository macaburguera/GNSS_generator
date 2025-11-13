function T0 = base_period_s(band_tok)
% Returns the fundamental code period (seconds) for each GNSS signal token
% as used by GNSSsignalgen.m in your repo.

    b = upper(strrep(strtrim(band_tok),' ', ''));
    switch b
        case {'L1','L1CA'}
            T0 = 1e-3;           % 1 ms
        case {'L2CM'}
            T0 = 20e-3;          % 20 ms
        case {'L2CL'}
            T0 = 1.5;            % 1.5 s
        case {'L2C'}
            T0 = 1.5;            % composed; effective 1.5 s
        case {'L5'}
            T0 = 1e-3;           % 1 ms
        case {'L5+'}
            T0 = 20e-3;          % 20 ms (secondary)
        case {'E1','E1OS'}
            T0 = 4e-3;           % 4 ms
        case {'E1OS+'}
            T0 = 100e-3;         % 100 ms (secondary)
        case {'E5','E5A','E5B'}
            T0 = 1e-3;           % 1 ms
        case {'E5+'}
            T0 = 100e-3;         % 100 ms (secondary)
        otherwise
            T0 = 1e-3;           % safe default
    end
end
