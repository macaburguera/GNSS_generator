
function y = lin2db(x)
%LIN2DB Convert linear ratio to dB
%   y = 10*log10(max(x, eps))
    y = 10*log10(max(x, eps));
end
