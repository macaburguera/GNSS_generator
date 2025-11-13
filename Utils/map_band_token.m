function out = map_band_token(band)
% Normalizes loose tokens (e.g., 'L1','E1') to the exact strings
% expected by GNSSsignalgen.m

    b = upper(strtrim(band));
    switch b
        case {'L1','L1CA'}
            out = 'L1CA';
        case {'L2','L2C'}
            out = 'L2C';
        case 'L2CM'
            out = 'L2CM';
        case 'L2CL'
            out = 'L2CL';
        case 'L5'
            out = 'L5';
        case {'L5PLUS','L5+'}
            out = 'L5+';
        case {'E1','E1OS'}
            out = 'E1OS';
        case {'E1PLUS','E1OS+'}
            out = 'E1OS+';
        case {'E5'}
            out = 'E5';
        case 'E5A'
            out = 'E5A';
        case 'E5B'
            out = 'E5B';
        case {'E5PLUS','E5+'}
            out = 'E5+';
        otherwise
            out = band; % pass-through
    end
end
