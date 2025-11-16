function [x, meta] = jam_none(N, ~, params)
% NO-JAM signal: zeros — realism comes from front-end later
x = complex(zeros(N,1));
meta = struct('note','nojam (front-end will add idle DC/AGC/quant effects)');
if nargin>2 && ~isempty(params), meta.params = params; end
end
