
function y = softclip(x, limit, knee)
%SOFTCLIP Soft clipper with smooth knee
%   limit: linear full-scale (e.g., 1)
%   knee:  knee region width (e.g., 0.1)
% Piecewise: linear in |x|<=L-k; tanh soft compression in knee/outside.
    if nargin < 2, limit = 1.0; end
    if nargin < 3, knee = 0.1*limit; end
    a = limit - knee;
    y = x;
    mag = abs(x);
    linMask = (mag <= a);
    softMask = ~linMask;
    y(linMask) = x(linMask);
    % Scale the soft region using tanh so it asymptotically approaches limit
    s = (mag(softMask) - a)/max(knee, eps);
    y(softMask) = sign(x(softMask)).*(a + knee*tanh(s));
end
