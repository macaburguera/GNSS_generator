function nm = localMap(code)
switch code
    case 1,  nm = 'NoJam';
    case 2,  nm = 'SingleAM';
    case 3,  nm = 'SingleChirp';
    case 5,  nm = 'SingleFM';
    case 9,  nm = 'DME';
    case 10, nm = 'NB';
    otherwise, nm = '';
end
end

